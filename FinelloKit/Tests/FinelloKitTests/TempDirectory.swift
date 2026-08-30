import Foundation

/// A scratch directory that cleans itself up, so tests never touch the real
/// Library.
final class TempDirectory {
    let url: URL

    init() {
        url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("finello-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    @discardableResult
    func writeFile(named name: String, contents: String = "pretend this is a video") -> URL {
        let file = url.appendingPathComponent(name, isDirectory: false)
        try? FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: file.path(percentEncoded: false), contents: Data(contents.utf8))
        return file
    }
}
