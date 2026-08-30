import Foundation
import SwiftData
import SwiftUI
import FinelloKit

enum CalendarMode: String, CaseIterable, Identifiable {
    case month
    case week

    var id: String { rawValue }
    var label: String { self == .month ? "Month" : "Week" }
}

@Observable
@MainActor
final class AppModel {
    let store: PostStore
    let thumbnails = ThumbnailLoader()
    let updates = UpdateController()
    let undoManager = UndoManager()

    var mode: CalendarMode = .month
    var anchor: Date
    var editingPost: Post?
    var showingOverdue = false

    /// Set when the on-disk store could not be opened. finello still runs, but
    /// in memory — better than refusing to launch on her machine with no
    /// explanation.
    let startupWarning: String?

    var calendar: Calendar { store.layout.calendar }
    var layout: CalendarLayout { store.layout }

    init() {
        let root = AppModel.supportDirectory()
        let library = MediaLibrary(root: root.appendingPathComponent("Library", isDirectory: true))
        var warning: String?
        var container: ModelContainer

        do {
            container = try PostStore.container(at: root.appendingPathComponent("finello.store"))
        } catch {
            // Opening a window with a visible warning beats refusing to launch
            // on her machine with no explanation.
            warning = """
                finello could not open its store at \(root.path(percentEncoded: false)) — \
                work from this session will not be saved. (\(error.localizedDescription))
                """
            // An in-memory container touches no disk and no permissions: if this
            // throws, SwiftData itself is broken and there is no finello to run.
            container = try! PostStore.inMemoryContainer()
        }

        self.startupWarning = warning
        self.store = PostStore(container: container, library: library)
        self.anchor = Calendar.current.startOfDay(for: Date())
        self.store.undoManager = undoManager
    }

    static func supportDirectory() -> URL {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )) ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("finello", isDirectory: true)
    }

    // MARK: Navigation

    var today: Date { store.today }

    func goToToday() {
        anchor = today
    }

    func step(_ direction: Int) {
        let component: Calendar.Component = mode == .month ? .month : .weekOfYear
        if let moved = calendar.date(byAdding: component, value: direction, to: anchor) {
            anchor = moved
        }
    }

    func reveal(_ post: Post) {
        anchor = post.day
        showingOverdue = false
        editingPost = post
    }

    var visibleRange: Range<Date>? {
        mode == .month
            ? layout.monthGridRange(containing: anchor)
            : layout.weekRange(containing: anchor)
    }

    var periodTitle: String {
        if mode == .month {
            return DateText.monthAndYear(anchor, calendar: calendar)
        }
        let days = layout.week(containing: anchor)
        guard let first = days.first, let last = days.last else { return "" }
        return "\(DateText.dayAndMonth(first, calendar: calendar)) – \(DateText.dayAndMonth(last, calendar: calendar))"
    }

    // MARK: Actions the views need

    func posts(on day: Date, within all: [Post]) -> [Post] {
        PostSelection.posts(on: day, in: all, calendar: calendar)
    }

    func overdue(within all: [Post]) -> [Post] {
        PostSelection.overdue(in: all, today: today, calendar: calendar)
    }

    func createPost(on day: Date) {
        guard let post = try? store.createPost(on: day) else { return }
        editingPost = post
    }

    func handleDroppedPost(identifier: String, onto day: Date) -> Bool {
        guard let uuid = UUID(uuidString: identifier),
              let post = try? store.post(withIdentifier: uuid) else { return false }
        try? store.reschedule(post, to: day)
        return true
    }

    func handleDroppedMedia(urls: [URL], onto day: Date) -> Bool {
        ((try? store.createPost(on: day, importing: urls)) ?? nil) != nil
    }
}
