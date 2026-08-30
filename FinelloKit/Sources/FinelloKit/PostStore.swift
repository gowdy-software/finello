import Foundation
import SwiftData

public enum PostStoreError: Error, Equatable {
    case mediaIndexOutOfRange(Int)
}

/// The single seam through which the rest of finello reads and writes.
///
/// Everything above it goes through these methods; nothing above it touches
/// SwiftData or the filesystem directly. It is constructed with a model
/// container and a Library, both injectable, so tests exercise real
/// persistence and real file operations pointed somewhere harmless.
@MainActor
public final class PostStore {
    public let container: ModelContainer
    public let library: MediaLibrary
    public let layout: CalendarLayout

    private let context: ModelContext
    private let now: () -> Date

    public init(
        container: ModelContainer,
        library: MediaLibrary,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.container = container
        self.library = library
        self.layout = CalendarLayout(calendar: calendar)
        self.context = container.mainContext
        self.now = now
    }

    public static func inMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Post.self, Variant.self, MediaItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    public static func container(at url: URL) throws -> ModelContainer {
        try ModelContainer(
            for: Post.self, Variant.self, MediaItem.self,
            configurations: ModelConfiguration(url: url)
        )
    }

    public var undoManager: UndoManager? {
        get { context.undoManager }
        set { context.undoManager = newValue }
    }

    public var today: Date { layout.startOfDay(now()) }

    // MARK: - Creating and deleting

    @discardableResult
    public func createPost(on day: Date, platforms: [Platform] = []) throws -> Post {
        let post = Post(day: layout.startOfDay(day))
        context.insert(post)
        try setPlatforms(platforms, on: post)
        try save()
        return post
    }

    /// Creates a Post from Media dropped straight onto a day.
    ///
    /// Returns nil, leaving nothing behind, when none of the files were usable
    /// — dropping a folder of text files should not litter the calendar with
    /// empty Posts.
    @discardableResult
    public func createPost(on day: Date, importing urls: [URL]) throws -> Post? {
        let post = try createPost(on: day)
        guard try addMedia(from: urls, to: post) > 0 else {
            try delete(post)
            return nil
        }
        return post
    }

    /// Deletes the Post and the Media only it referenced. Media is the
    /// irreplaceable thing in finello — she may have deleted the originals —
    /// so callers are expected to confirm first.
    public func delete(_ post: Post) throws {
        for item in post.media {
            try? library.remove(filename: item.filename)
        }
        context.delete(post)
        try save()
    }

    // MARK: - Querying

    public func posts(on day: Date) throws -> [Post] {
        let start = layout.startOfDay(day)
        guard let end = layout.calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let descriptor = FetchDescriptor<Post>(
            predicate: #Predicate { $0.day >= start && $0.day < end },
            sortBy: [SortDescriptor(\.day), SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    /// Looks a Post up by the stable identifier used as a drag payload.
    public func post(withIdentifier identifier: UUID) throws -> Post? {
        try context.fetch(
            FetchDescriptor<Post>(predicate: #Predicate { $0.identifier == identifier })
        ).first
    }

    public func allPosts() throws -> [Post] {
        try context.fetch(
            FetchDescriptor<Post>(sortBy: [SortDescriptor(\.day), SortDescriptor(\.createdAt)])
        )
    }

    // MARK: - Scheduling

    public func reschedule(_ post: Post, to day: Date) throws {
        post.day = layout.startOfDay(day)
        try save()
    }

    public func setTitle(_ title: String, on post: Post) throws {
        post.title = title
        try save()
    }

    // MARK: - Platforms and Variants

    /// Adds a Variant for each newly selected Platform and removes the Variants
    /// of deselected ones. Variants for Platforms that stay selected are left
    /// untouched, so her writing survives a change of mind about a different
    /// Platform.
    public func setPlatforms(_ platforms: [Platform], on post: Post) throws {
        let wanted = Set(platforms)
        let existing = Set(post.platforms)

        for platform in existing.subtracting(wanted) {
            if let variant = post.variant(for: platform) {
                context.delete(variant)
            }
        }
        for platform in wanted.subtracting(existing) {
            let variant = Variant(platform: platform)
            variant.post = post
            context.insert(variant)
        }
        try save()
    }

    /// Which of these Platforms would lose writing if they were deselected.
    /// The UI warns with this rather than discarding silently.
    public func platformsWithWriting(_ platforms: [Platform], on post: Post) -> [Platform] {
        platforms.filter { post.variant(for: $0)?.hasWriting == true }.sorted()
    }

    public func setCaption(_ text: String, for platform: Platform, on post: Post) throws {
        post.variant(for: platform)?.caption = text
        try save()
    }

    public func setDescription(_ text: String, for platform: Platform, on post: Post) throws {
        post.variant(for: platform)?.descriptionText = text
        try save()
    }

    public func setHashtags(_ text: String, for platform: Platform, on post: Post) throws {
        post.variant(for: platform)?.hashtags = text
        try save()
    }

    /// Pulls another Platform's writing across as a starting point, which is
    /// how she actually works: write the long one, then cut it down.
    public func copyWriting(from source: Platform, to target: Platform, on post: Post) throws {
        guard let from = post.variant(for: source), let to = post.variant(for: target) else { return }
        to.caption = from.caption
        to.descriptionText = from.descriptionText
        to.hashtags = from.hashtags
        try save()
    }

    // MARK: - Done

    public func setDone(_ done: Bool, for platform: Platform, on post: Post) throws {
        post.variant(for: platform)?.isDone = done
        try save()
    }

    public func toggleDone(for platform: Platform, on post: Post) throws {
        guard let variant = post.variant(for: platform) else { return }
        try setDone(!variant.isDone, for: platform, on: post)
    }

    // MARK: - Media

    @discardableResult
    public func addMedia(from source: URL, to post: Post) throws -> MediaItem {
        let imported = try library.importFile(at: source)
        let nextOrder = (post.media.map(\.order).max() ?? -1) + 1
        let item = MediaItem(filename: imported.filename, kind: imported.kind, order: nextOrder)
        item.post = post
        context.insert(item)
        try save()
        return item
    }

    /// Adds everything that is usable and reports how many made it, so callers
    /// do not each re-implement the skip-what-we-cannot-read loop.
    @discardableResult
    public func addMedia(from urls: [URL], to post: Post) throws -> Int {
        var imported = 0
        for url in urls where (try? addMedia(from: url, to: post)) != nil {
            imported += 1
        }
        return imported
    }

    public func moveMedia(on post: Post, from source: Int, to destination: Int) throws {
        var ordered = post.orderedMedia
        guard ordered.indices.contains(source) else {
            throw PostStoreError.mediaIndexOutOfRange(source)
        }
        guard destination >= 0 && destination < ordered.count else {
            throw PostStoreError.mediaIndexOutOfRange(destination)
        }
        let item = ordered.remove(at: source)
        ordered.insert(item, at: destination)
        for (index, item) in ordered.enumerated() { item.order = index }
        try save()
    }

    public func removeMedia(at index: Int, from post: Post) throws {
        let ordered = post.orderedMedia
        guard ordered.indices.contains(index) else {
            throw PostStoreError.mediaIndexOutOfRange(index)
        }
        let item = ordered[index]
        try? library.remove(filename: item.filename)

        // Renumber from the list we already hold rather than re-reading the
        // relationship: the deleted item is still in it until the context
        // flushes, and renumbering that would leave a gap in the order.
        var remaining = ordered
        remaining.remove(at: index)
        item.post = nil
        context.delete(item)
        for (position, remainingItem) in remaining.enumerated() { remainingItem.order = position }
        try save()
    }

    public func url(for item: MediaItem) -> URL {
        library.url(for: item.filename)
    }

    // MARK: - Persistence

    public func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}
