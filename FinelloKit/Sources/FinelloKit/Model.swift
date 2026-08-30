import Foundation
import SwiftData

/// How much of a Post has actually gone out. Never stored — always derived
/// from the Variants, so it cannot drift from them.
public enum DoneState: String, Sendable, Equatable {
    case none
    case some
    case all
}

/// One Platform's version of a Post: its own wording and its own checkmark.
/// Carries no Media and no date of its own.
@Model
public final class Variant {
    /// Persisted as a string rather than a database enum (see `Platform`).
    public var platformID: String = Platform.instagram.rawValue
    public var caption: String = ""
    public var descriptionText: String = ""
    public var hashtags: String = ""
    public var isDone: Bool = false
    public var post: Post?

    public init(platform: Platform) {
        self.platformID = platform.rawValue
    }

    public var platform: Platform? { Platform(rawValue: platformID) }

    /// Whether removing this Variant would lose writing she has done.
    public var hasWriting: Bool {
        !caption.trimmed.isEmpty || !descriptionText.trimmed.isEmpty || !hashtags.trimmed.isEmpty
    }
}

/// One photo, video or audio file in the Library, in its place in a Post's
/// carousel order.
@Model
public final class MediaItem {
    public var filename: String = ""
    public var kindRaw: String = MediaKind.image.rawValue
    public var order: Int = 0
    public var post: Post?

    public init(filename: String, kind: MediaKind, order: Int) {
        self.filename = filename
        self.kindRaw = kind.rawValue
        self.order = order
    }

    public var kind: MediaKind { MediaKind(rawValue: kindRaw) ?? .image }
}

/// One planned piece of content on one day.
@Model
public final class Post {
    public var identifier: UUID = UUID()
    /// Normalised to the start of the day. finello has no notion of time of day.
    public var day: Date = Date()
    public var title: String = ""
    /// Only used to order several Posts within one day; finello has no time of day.
    public var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Variant.post)
    public var variants: [Variant] = []

    @Relationship(deleteRule: .cascade, inverse: \MediaItem.post)
    public var media: [MediaItem] = []

    public init(day: Date) {
        self.day = day
    }

    // MARK: Derived state
    //
    // None of this is stored. Storing it would create a second source of truth
    // that could drift from the Variants it comes from.

    /// Always in Platform declaration order, so the editor's tabs never
    /// reshuffle under her.
    public var orderedVariants: [Variant] {
        variants.sorted { ($0.platform ?? .instagram) < ($1.platform ?? .instagram) }
    }

    public var orderedMedia: [MediaItem] {
        media.sorted { $0.order < $1.order }
    }

    public var platforms: [Platform] {
        orderedVariants.compactMap(\.platform)
    }

    public var doneState: DoneState {
        guard !variants.isEmpty else { return .none }
        let done = variants.filter(\.isDone).count
        if done == 0 { return .none }
        return done == variants.count ? .all : .some
    }

    public var doneCount: Int { variants.filter(\.isDone).count }

    public func variant(for platform: Platform) -> Variant? {
        variants.first { $0.platformID == platform.rawValue }
    }

    /// A Post whose day has passed with something still owed. finello flags it
    /// and never moves it: the calendar stays an honest record of what was
    /// planned and when.
    public func isOverdue(today: Date, calendar: Calendar = .current) -> Bool {
        day < calendar.startOfDay(for: today) && doneState != .all
    }

    public func displayTitle(calendar: Calendar = .current, locale: Locale = .current) -> String {
        TitleDerivation.displayTitle(
            title: title,
            captions: orderedVariants.map(\.caption),
            day: day,
            calendar: calendar,
            locale: locale
        )
    }
}
