import SwiftUI
import UniformTypeIdentifiers
import FinelloKit

/// A day accepts two very different drops: Media files from Finder, and a Post
/// being moved from another day.
///
/// These have to share one drop handler. Two `.dropDestination` modifiers on
/// the same view do not coexist — only one is honoured and the other silently
/// does nothing.
enum DropRouter {
    @MainActor
    static func handle(_ providers: [NSItemProvider], onto day: Date, app: AppModel) -> Bool {
        let files = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        if !files.isEmpty {
            let collector = MediaDropCollector(expected: files.count, day: day, app: app)
            for provider in files {
                // The provider itself must not cross into the main actor: it is
                // not Sendable. Only the URL it yields does.
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    let url = DropRouter.url(from: item)
                    Task { @MainActor in collector.add(url) }
                }
            }
            return true
        }

        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.text.identifier)
        }) else { return false }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let identifier = DropRouter.string(from: item)
            Task { @MainActor in
                guard let identifier else { return }
                _ = app.handleDroppedPost(identifier: identifier, onto: day)
            }
        }
        return true
    }

    private static func url(from item: NSSecureCoding?) -> URL? {
        if let data = item as? Data { return URL(dataRepresentation: data, relativeTo: nil) }
        if let url = item as? URL { return url }
        return nil
    }

    private static func string(from item: NSSecureCoding?) -> String? {
        if let data = item as? Data { return String(data: data, encoding: .utf8) }
        if let text = item as? String { return text }
        return nil
    }
}

/// Files arrive one callback at a time. This gathers them and imports the whole
/// drop in one go, so dropping five photos makes one Post rather than five.
@MainActor
private final class MediaDropCollector {
    private var urls: [URL] = []
    private var remaining: Int
    private let day: Date
    private let app: AppModel

    init(expected: Int, day: Date, app: AppModel) {
        self.remaining = expected
        self.day = day
        self.app = app
    }

    func add(_ url: URL?) {
        if let url { urls.append(url) }
        remaining -= 1
        guard remaining == 0, !urls.isEmpty else { return }
        _ = app.handleDroppedMedia(urls: urls, onto: day)
    }
}

extension View {
    /// Accepts both Media files and a Post being rescheduled onto this day.
    func dayDropTarget(day: Date, app: AppModel, isTargeted: Binding<Bool>) -> some View {
        onDrop(of: [.fileURL, .text], isTargeted: isTargeted) { providers in
            DropRouter.handle(providers, onto: day, app: app)
        }
    }

    /// A cell is only draggable when there is actually a Post in it.
    @ViewBuilder
    func draggablePost(_ post: Post?) -> some View {
        if let post {
            draggable(post.identifier.uuidString)
        } else {
            self
        }
    }
}
