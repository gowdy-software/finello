import Foundation
import Testing
@testable import FinelloKit

@Suite("Media library")
struct MediaLibraryTests {

    func makeLibrary(_ temp: TempDirectory) throws -> MediaLibrary {
        MediaLibrary(root: temp.url.appendingPathComponent("Library", isDirectory: true))
    }

    @Test("creates its own directory on the first add")
    func createsRoot() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        #expect(!FileManager.default.fileExists(atPath: library.root.path(percentEncoded: false)))
        _ = try library.importFile(at: temp.writeFile(named: "clip.mov"))
        #expect(FileManager.default.fileExists(atPath: library.root.path(percentEncoded: false)))
    }

    @Test("heals a Library folder that was deleted underneath it")
    func healsDeletedRoot() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        _ = try library.importFile(at: temp.writeFile(named: "first.mov"))
        try FileManager.default.removeItem(at: library.root)

        let second = try library.importFile(at: temp.writeFile(named: "second.mov"))
        #expect(library.contains(filename: second.filename))
    }

    @Test("copies the file in and leaves the original alone")
    func copiesIn() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        let source = temp.writeFile(named: "clip.mov", contents: "footage")

        let imported = try library.importFile(at: source)

        #expect(library.contains(filename: imported.filename))
        #expect(FileManager.default.fileExists(atPath: source.path(percentEncoded: false)),
                "the original must survive: she may not know finello took a copy")
        let copied = try String(contentsOf: library.url(for: imported.filename), encoding: .utf8)
        #expect(copied == "footage")
    }

    @Test("survives the original being deleted afterwards")
    func survivesOriginalDeletion() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        let source = temp.writeFile(named: "clip.mov", contents: "footage")
        let imported = try library.importFile(at: source)

        try FileManager.default.removeItem(at: source)

        #expect(library.contains(filename: imported.filename))
        let copied = try String(contentsOf: library.url(for: imported.filename), encoding: .utf8)
        #expect(copied == "footage")
    }

    @Test("two files with the same name do not collide")
    func noNameCollision() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        let first = temp.writeFile(named: "a/IMG_0001.jpg", contents: "one")
        let second = temp.writeFile(named: "b/IMG_0001.jpg", contents: "two")

        let a = try library.importFile(at: first)
        let b = try library.importFile(at: second)

        #expect(a.filename != b.filename)
        #expect(try String(contentsOf: library.url(for: a.filename), encoding: .utf8) == "one")
        #expect(try String(contentsOf: library.url(for: b.filename), encoding: .utf8) == "two")
    }

    @Test("keeps the file extension so the type stays readable")
    func keepsExtension() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        let imported = try library.importFile(at: temp.writeFile(named: "clip.MOV"))
        #expect(imported.filename.hasSuffix(".mov"))
    }

    @Test("recognises the kind of media", arguments: [
        ("photo.jpg", MediaKind.image), ("photo.png", .image), ("photo.heic", .image),
        ("clip.mov", .video), ("clip.mp4", .video), ("clip.m4v", .video),
        ("voice.m4a", .audio), ("voice.mp3", .audio), ("voice.wav", .audio),
    ])
    func detectsKind(name: String, expected: MediaKind) throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        #expect(try library.importFile(at: temp.writeFile(named: name)).kind == expected)
    }

    @Test("refuses a file that is not media")
    func refusesNonMedia() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        let source = temp.writeFile(named: "notes.txt")
        #expect(throws: MediaLibraryError.unsupportedType(source)) {
            try library.importFile(at: source)
        }
    }

    @Test("reports a source that is not there")
    func refusesMissingSource() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        let missing = temp.url.appendingPathComponent("ghost.jpg")
        #expect(throws: MediaLibraryError.sourceMissing(missing)) {
            try library.importFile(at: missing)
        }
    }

    @Test("removes a file")
    func removes() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        let imported = try library.importFile(at: temp.writeFile(named: "clip.mov"))
        try library.remove(filename: imported.filename)
        #expect(!library.contains(filename: imported.filename))
    }

    @Test("removing something already gone is not an error")
    func removeIsIdempotent() throws {
        let temp = TempDirectory()
        let library = try makeLibrary(temp)
        try library.remove(filename: "never-existed.jpg")
    }
}
