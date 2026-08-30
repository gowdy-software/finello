import AVFoundation
// @preconcurrency because QLThumbnailRepresentation is not Sendable in the
// macOS 15 SDK, which is what CI builds against. Safe here: the representation
// never escapes — it is turned into an NSImage on the spot.
@preconcurrency import QuickLookThumbnailing
import SwiftUI
import FinelloKit

/// Generates and caches the still that represents a Media item.
///
/// Videos deliberately do not go through QuickLook: the poster frame is taken
/// a second in (see `PosterFrame`), because leading frames are so often black
/// or a fade that a naive grab would give a grid of black rectangles.
@MainActor
@Observable
final class ThumbnailLoader {
    private var cache: [String: NSImage] = [:]
    private var inFlight: Set<String> = []

    func cached(_ filename: String) -> NSImage? { cache[filename] }

    func image(for item: MediaItem, url: URL, size: CGSize) async -> NSImage? {
        if let hit = cache[item.filename] { return hit }
        guard !inFlight.contains(item.filename) else { return nil }
        inFlight.insert(item.filename)
        defer { inFlight.remove(item.filename) }

        let image: NSImage?
        switch item.kind {
        case .video: image = await Self.videoPoster(url: url, size: size)
        case .image, .audio: image = await Self.quickLook(url: url, size: size)
        }
        if let image { cache[item.filename] = image }
        return image
    }

    func forget(_ filename: String) { cache[filename] = nil }

    private static func videoPoster(url: URL, size: CGSize) async -> NSImage? {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else { return nil }
        let offset = PosterFrame.offset(forDuration: duration.seconds)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: size.width * 2, height: size.height * 2)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.3, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.3, preferredTimescale: 600)

        let time = CMTime(seconds: offset, preferredTimescale: 600)
        guard let (cgImage, _) = try? await generator.image(at: time) else {
            return await quickLook(url: url, size: size)
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    private static func quickLook(url: URL, size: CGSize) async -> NSImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: max(size.width, 64), height: max(size.height, 64)),
            scale: 2,
            representationTypes: .thumbnail
        )
        guard let rep = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request) else {
            return nil
        }
        return rep.nsImage
    }
}

/// One Media item drawn to fill its space, with a placeholder while the
/// thumbnail is being made.
struct MediaThumbnail: View {
    let item: MediaItem
    var contentMode: ContentMode = .fill

    @Environment(AppModel.self) private var app
    @State private var image: NSImage?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: placeholderSymbol)
                                .font(.title3)
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .task(id: item.filename) {
                image = await app.thumbnails.image(
                    for: item, url: app.store.url(for: item), size: proxy.size
                )
            }
        }
    }

    private var placeholderSymbol: String {
        switch item.kind {
        case .image: "photo"
        case .video: "film"
        case .audio: "waveform"
        }
    }
}
