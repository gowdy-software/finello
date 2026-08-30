import Foundation
import UniformTypeIdentifiers
#if canImport(Darwin)
import Darwin
#endif

public enum MediaKind: String, Codable, Sendable {
    case image
    case video
    case audio
}

public struct ImportedMedia: Sendable, Equatable {
    public let filename: String
    public let kind: MediaKind
}

public enum MediaLibraryError: Error, Equatable {
    case sourceMissing(URL)
    case unsupportedType(URL)
}

/// finello's own store of Media on disk.
///
/// Media is copied in when she adds it and finello owns the copy from then on,
/// so moving, renaming or deleting the original never breaks her calendar
/// (ADR 0002). Filenames are generated rather than taken from the source, so
/// two files called `IMG_0001.mov` cannot collide.
public struct MediaLibrary: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    /// Created on demand rather than at construction, so that finello can
    /// always be built, and so a Library folder deleted while the app is
    /// running heals itself on the next add.
    private func ensureRoot() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    public func url(for filename: String) -> URL {
        root.appendingPathComponent(filename, isDirectory: false)
    }

    public func contains(filename: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: filename).path(percentEncoded: false))
    }

    public func importFile(at source: URL) throws -> ImportedMedia {
        guard FileManager.default.fileExists(atPath: source.path(percentEncoded: false)) else {
            throw MediaLibraryError.sourceMissing(source)
        }
        guard let kind = Self.kind(of: source) else {
            throw MediaLibraryError.unsupportedType(source)
        }
        try ensureRoot()

        let ext = source.pathExtension.lowercased()
        let filename = ext.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(ext)"
        let destination = url(for: filename)

        try copy(from: source, to: destination)
        return ImportedMedia(filename: filename, kind: kind)
    }

    public func remove(filename: String) throws {
        let target = url(for: filename)
        guard FileManager.default.fileExists(atPath: target.path(percentEncoded: false)) else { return }
        try FileManager.default.removeItem(at: target)
    }

    /// Clones on APFS when the source is on the same volume, which is instant
    /// and costs no extra disk until one copy is modified. Falls back to a real
    /// copy across volumes (an SD card, an external drive), which is what we
    /// want there anyway.
    private func copy(from source: URL, to destination: URL) throws {
        #if canImport(Darwin)
        let cloned = source.path(percentEncoded: false).withCString { src in
            destination.path(percentEncoded: false).withCString { dst in
                clonefile(src, dst, 0) == 0
            }
        }
        if cloned { return }
        #endif
        try FileManager.default.copyItem(at: source, to: destination)
    }

    static func kind(of url: URL) -> MediaKind? {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else { return nil }
        if type.conforms(to: .image) { return .image }
        if type.conforms(to: .movie) || type.conforms(to: .video) { return .video }
        if type.conforms(to: .audio) { return .audio }
        return nil
    }
}
