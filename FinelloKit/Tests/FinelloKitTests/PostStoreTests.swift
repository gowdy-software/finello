import Foundation
import Testing
@testable import FinelloKit

/// Holds the store together with the scratch directory its Library lives in,
/// so the directory survives as long as the test needs it.
@MainActor
struct Fixture {
    let store: PostStore
    let temp: TempDirectory
    let calendar: Calendar

    init(today: Date? = nil, firstWeekday: Int = 2) throws {
        let cal = Fixed.calendar(firstWeekday: firstWeekday)
        let temp = TempDirectory()
        let library = MediaLibrary(root: temp.url.appendingPathComponent("Library", isDirectory: true))
        let fixedToday = today ?? Fixed.date(2026, 8, 26, calendar: cal)
        self.calendar = cal
        self.temp = temp
        self.store = PostStore(
            container: try PostStore.inMemoryContainer(),
            library: library,
            calendar: cal,
            now: { fixedToday }
        )
    }

    func date(_ y: Int, _ m: Int, _ d: Int) -> Date { Fixed.date(y, m, d, calendar: calendar) }

    /// Exactly what CalendarScreen does: select over everything @Query holds.
    func overdue() throws -> [Post] {
        PostSelection.overdue(in: try store.allPosts(), today: store.today, calendar: calendar)
    }

    /// Exactly what MonthView does: walk the grid, select each day.
    func inMonthGrid(containing date: Date) throws -> [Post] {
        let all = try store.allPosts()
        return store.layout.monthGrid(containing: date).flatMap {
            PostSelection.posts(on: $0.date, in: all, calendar: calendar)
        }
    }

    /// Exactly what WeekView does.
    func inWeek(containing date: Date) throws -> [Post] {
        let all = try store.allPosts()
        return store.layout.week(containing: date).flatMap {
            PostSelection.posts(on: $0, in: all, calendar: calendar)
        }
    }
    func sourceFile(named name: String, contents: String = "bytes") -> URL {
        temp.writeFile(named: "sources/\(UUID().uuidString)/\(name)", contents: contents)
    }
}

@Suite("Creating Posts")
@MainActor
struct CreatePostTests {

    @Test("puts the Post on the day she chose")
    func createsOnDay() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        #expect(post.day == f.date(2026, 9, 3))
        #expect(try f.store.posts(on: f.date(2026, 9, 3)).count == 1)
    }

    @Test("normalises away any time of day")
    func normalisesTime() throws {
        let f = try Fixture()
        let midAfternoon = f.date(2026, 9, 3).addingTimeInterval(15 * 3600 + 42 * 60)
        let post = try f.store.createPost(on: midAfternoon)
        #expect(post.day == f.date(2026, 9, 3))
    }

    @Test("creates a Variant for each Platform she picked, in Platform order")
    func createsVariants() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.linkedin, .instagram, .tiktok])
        #expect(post.platforms == [.instagram, .tiktok, .linkedin])
    }

    @Test("can hold an idea with no Media and no Platforms yet")
    func bareIdea() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        #expect(post.media.isEmpty)
        #expect(post.variants.isEmpty)
        #expect(post.doneState == .none)
    }

    @Test("lets one day hold several Posts")
    func severalPostsOneDay() throws {
        let f = try Fixture()
        let day = f.date(2026, 9, 3)
        try f.store.createPost(on: day, platforms: [.tiktok])
        try f.store.createPost(on: day, platforms: [.instagram])
        #expect(try f.store.posts(on: day).count == 2)
    }

    @Test("orders several Posts on one day by when they were made")
    func stableOrderWithinDay() throws {
        let f = try Fixture()
        let day = f.date(2026, 9, 3)
        let first = try f.store.createPost(on: day)
        try f.store.setTitle("first", on: first)
        let second = try f.store.createPost(on: day)
        try f.store.setTitle("second", on: second)
        #expect(try f.store.posts(on: day).map(\.title) == ["first", "second"])
    }
}

@Suite("Platforms and Variants")
@MainActor
struct PlatformTests {

    @Test("adds a Variant when she selects a new Platform")
    func addsVariant() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram])
        try f.store.setPlatforms([.instagram, .youtube], on: post)
        #expect(post.platforms == [.instagram, .youtube])
    }

    @Test("removes the Variant when she deselects a Platform")
    func removesVariant() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .youtube])
        try f.store.setPlatforms([.instagram], on: post)
        #expect(post.platforms == [.instagram])
        #expect(post.variant(for: .youtube) == nil)
    }

    @Test("leaves the writing of Platforms she kept untouched")
    func keepsExistingWriting() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .tiktok])
        try f.store.setCaption("the long one", for: .instagram, on: post)
        try f.store.setPlatforms([.instagram, .linkedin], on: post)
        #expect(post.variant(for: .instagram)?.caption == "the long one")
    }

    @Test("reports which Platforms would lose writing before they are dropped")
    func warnsBeforeLosingWriting() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .tiktok, .youtube])
        try f.store.setCaption("something", for: .tiktok, on: post)
        try f.store.setHashtags("#tags", for: .youtube, on: post)
        #expect(f.store.platformsWithWriting([.instagram, .tiktok, .youtube], on: post) == [.tiktok, .youtube])
    }

    @Test("a Variant with only a Done tick counts as empty writing")
    func doneIsNotWriting() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram])
        try f.store.setDone(true, for: .instagram, on: post)
        #expect(f.store.platformsWithWriting([.instagram], on: post).isEmpty)
    }

    @Test("copies another Platform's writing across as a starting point")
    func copyWriting() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .tiktok])
        try f.store.setCaption("The long Instagram version", for: .instagram, on: post)
        try f.store.setHashtags("#one #two", for: .instagram, on: post)

        try f.store.copyWriting(from: .instagram, to: .tiktok, on: post)

        #expect(post.variant(for: .tiktok)?.caption == "The long Instagram version")
        #expect(post.variant(for: .tiktok)?.hashtags == "#one #two")
        #expect(post.variant(for: .tiktok)?.isDone == false, "copying writing must not copy progress")
    }

    @Test("copying from a Platform that is not selected does nothing")
    func copyFromAbsentPlatform() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.tiktok])
        try f.store.copyWriting(from: .snapchat, to: .tiktok, on: post)
        #expect(post.variant(for: .tiktok)?.caption == "")
    }
}

@Suite("Done state")
@MainActor
struct DoneStateTests {

    @Test("a Post with no Variants has nothing done")
    func noVariants() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        #expect(post.doneState == .none)
    }

    @Test("is none until she ticks something")
    func none() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .tiktok])
        #expect(post.doneState == .none)
    }

    @Test("is some when part of it has gone out")
    func some() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .tiktok, .youtube])
        try f.store.setDone(true, for: .tiktok, on: post)
        #expect(post.doneState == .some)
        #expect(post.doneCount == 1)
    }

    @Test("is all only when every Platform has gone out")
    func all() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .tiktok])
        try f.store.setDone(true, for: .instagram, on: post)
        try f.store.setDone(true, for: .tiktok, on: post)
        #expect(post.doneState == .all)
    }

    @Test("un-ticking takes it back")
    func untick() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram])
        try f.store.toggleDone(for: .instagram, on: post)
        #expect(post.doneState == .all)
        try f.store.toggleDone(for: .instagram, on: post)
        #expect(post.doneState == .none)
    }

    @Test("dropping the only outstanding Platform completes the Post")
    func droppingOutstandingPlatform() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .snapchat])
        try f.store.setDone(true, for: .instagram, on: post)
        #expect(post.doneState == .some)
        try f.store.setPlatforms([.instagram], on: post)
        #expect(post.doneState == .all)
    }
}

@Suite("Overdue")
@MainActor
struct OverdueTests {
    let today = Fixed.date(2026, 8, 26)

    @Test("a past Post with something outstanding is overdue")
    func pastOutstanding() throws {
        let f = try Fixture(today: today)
        let post = try f.store.createPost(on: f.date(2026, 8, 20), platforms: [.instagram, .tiktok])
        try f.store.setDone(true, for: .instagram, on: post)
        #expect(post.isOverdue(today: today, calendar: f.calendar))
        #expect(try f.overdue().count == 1)
    }

    @Test("a past Post that fully went out is not overdue")
    func pastComplete() throws {
        let f = try Fixture(today: today)
        let post = try f.store.createPost(on: f.date(2026, 8, 20), platforms: [.instagram])
        try f.store.setDone(true, for: .instagram, on: post)
        #expect(!post.isOverdue(today: today, calendar: f.calendar))
        #expect(try f.overdue().count == 0)
    }

    @Test("today's Post is not overdue, however little of it is done")
    func todayIsNotOverdue() throws {
        let f = try Fixture(today: today)
        let post = try f.store.createPost(on: today, platforms: [.instagram])
        #expect(!post.isOverdue(today: today, calendar: f.calendar))
        #expect(try f.overdue().count == 0)
    }

    @Test("a future Post is not overdue")
    func futureIsNotOverdue() throws {
        let f = try Fixture(today: today)
        let post = try f.store.createPost(on: f.date(2026, 9, 10), platforms: [.instagram])
        #expect(!post.isOverdue(today: today, calendar: f.calendar))
    }

    @Test("a past idea with no Platforms at all is still outstanding")
    func pastBareIdea() throws {
        let f = try Fixture(today: today)
        try f.store.createPost(on: f.date(2026, 8, 20))
        #expect(try f.overdue().count == 1)
    }

    @Test("lists overdue Posts oldest first")
    func listedOldestFirst() throws {
        let f = try Fixture(today: today)
        try f.store.createPost(on: f.date(2026, 8, 24), platforms: [.tiktok])
        try f.store.createPost(on: f.date(2026, 8, 11), platforms: [.tiktok])
        try f.store.createPost(on: f.date(2026, 8, 18), platforms: [.tiktok])
        let days = try f.overdue().map(\.day)
        #expect(days == [f.date(2026, 8, 11), f.date(2026, 8, 18), f.date(2026, 8, 24)])
    }

    @Test("reading the overdue list never moves a Post")
    func neverMovesADate() throws {
        let f = try Fixture(today: today)
        let post = try f.store.createPost(on: f.date(2026, 8, 11), platforms: [.tiktok])
        _ = try f.overdue()
        _ = try f.overdue().count
        #expect(post.day == f.date(2026, 8, 11), "finello must never rewrite her history")
    }

    @Test("ticking the last Platform clears it from the overdue list")
    func tickingClearsIt() throws {
        let f = try Fixture(today: today)
        let post = try f.store.createPost(on: f.date(2026, 8, 20), platforms: [.youtube])
        #expect(try f.overdue().count == 1)
        try f.store.setDone(true, for: .youtube, on: post)
        #expect(try f.overdue().count == 0)
    }
}

@Suite("Media on a Post")
@MainActor
struct PostMediaTests {

    @Test("copies Media into the Library and attaches it to the Post")
    func addsMedia() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        let item = try f.store.addMedia(from: f.sourceFile(named: "clip.mov"), to: post)

        #expect(post.orderedMedia.count == 1)
        #expect(item.kind == .video)
        #expect(f.store.library.contains(filename: item.filename))
    }

    @Test("keeps Media in the order she added it")
    func keepsOrder() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        for name in ["a.jpg", "b.jpg", "c.jpg"] {
            try f.store.addMedia(from: f.sourceFile(named: name, contents: name), to: post)
        }
        #expect(post.orderedMedia.map(\.order) == [0, 1, 2])
        let contents = try post.orderedMedia.map {
            try String(contentsOf: f.store.url(for: $0), encoding: .utf8)
        }
        #expect(contents == ["a.jpg", "b.jpg", "c.jpg"])
    }

    @Test("reorders the carousel when she drags an item")
    func reorders() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        for name in ["a.jpg", "b.jpg", "c.jpg"] {
            try f.store.addMedia(from: f.sourceFile(named: name, contents: name), to: post)
        }
        try f.store.moveMedia(on: post, from: 2, to: 0)
        let contents = try post.orderedMedia.map {
            try String(contentsOf: f.store.url(for: $0), encoding: .utf8)
        }
        #expect(contents == ["c.jpg", "a.jpg", "b.jpg"])
        #expect(post.orderedMedia.map(\.order) == [0, 1, 2], "order stays a dense sequence")
    }

    @Test("rejects a reorder outside the carousel", arguments: [(5, 0), (0, 9), (0, -1)])
    func rejectsBadReorder(from: Int, to: Int) throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        try f.store.addMedia(from: f.sourceFile(named: "a.jpg"), to: post)
        #expect(throws: (any Error).self) {
            try f.store.moveMedia(on: post, from: from, to: to)
        }
    }

    @Test("removing Media deletes it from the Library and closes the gap")
    func removesMedia() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        for name in ["a.jpg", "b.jpg", "c.jpg"] {
            try f.store.addMedia(from: f.sourceFile(named: name, contents: name), to: post)
        }
        let removed = post.orderedMedia[1].filename

        try f.store.removeMedia(at: 1, from: post)

        #expect(post.orderedMedia.count == 2)
        #expect(post.orderedMedia.map(\.order) == [0, 1])
        #expect(!f.store.library.contains(filename: removed))
    }

    @Test("rejects removing Media that is not there")
    func rejectsBadRemoval() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        #expect(throws: PostStoreError.mediaIndexOutOfRange(0)) {
            try f.store.removeMedia(at: 0, from: post)
        }
    }

    @Test("refuses a file that is not media and leaves the Post unchanged")
    func refusesNonMedia() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        #expect(throws: (any Error).self) {
            try f.store.addMedia(from: f.sourceFile(named: "notes.txt"), to: post)
        }
        #expect(post.media.isEmpty)
    }

    @Test("deleting a Post takes its Media out of the Library with it")
    func deleteRemovesMedia() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram])
        let item = try f.store.addMedia(from: f.sourceFile(named: "clip.mov"), to: post)
        let filename = item.filename

        try f.store.delete(post)

        #expect(try f.store.allPosts().isEmpty)
        #expect(!f.store.library.contains(filename: filename))
    }
}

@Suite("Rescheduling")
@MainActor
struct ReschedulingTests {

    @Test("moves the Post to the day she dropped it on")
    func moves() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        try f.store.reschedule(post, to: f.date(2026, 9, 7))
        #expect(post.day == f.date(2026, 9, 7))
        #expect(try f.store.posts(on: f.date(2026, 9, 3)).isEmpty)
        #expect(try f.store.posts(on: f.date(2026, 9, 7)).count == 1)
    }

    @Test("dropping onto a day that already has a Post adds to it")
    func stacksOnExistingDay() throws {
        let f = try Fixture()
        let existing = try f.store.createPost(on: f.date(2026, 9, 7))
        let moved = try f.store.createPost(on: f.date(2026, 9, 3))
        try f.store.reschedule(moved, to: f.date(2026, 9, 7))
        #expect(try f.store.posts(on: f.date(2026, 9, 7)).count == 2)
        #expect(existing.day == moved.day)
    }

    @Test("keeps Media, writing and progress across a move")
    func preservesEverything() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.tiktok])
        try f.store.addMedia(from: f.sourceFile(named: "clip.mov"), to: post)
        try f.store.setCaption("hello", for: .tiktok, on: post)
        try f.store.setDone(true, for: .tiktok, on: post)

        try f.store.reschedule(post, to: f.date(2026, 9, 7))

        #expect(post.orderedMedia.count == 1)
        #expect(post.variant(for: .tiktok)?.caption == "hello")
        #expect(post.doneState == .all)
    }
}

@Suite("What the calendar views select")
@MainActor
struct CalendarQueryTests {

    @Test("a month query includes the leading and trailing days the grid shows")
    func monthIncludesGridEdges() throws {
        let f = try Fixture()
        // The September 2026 grid, week starting Monday, opens on 31 August.
        try f.store.createPost(on: f.date(2026, 8, 31), platforms: [.tiktok])
        try f.store.createPost(on: f.date(2026, 9, 15), platforms: [.tiktok])
        let posts = try f.inMonthGrid(containing: f.date(2026, 9, 15))
        #expect(posts.count == 2)
    }

    @Test("a month query excludes days the grid does not show")
    func monthExcludesFarDays() throws {
        let f = try Fixture()
        try f.store.createPost(on: f.date(2026, 7, 15), platforms: [.tiktok])
        try f.store.createPost(on: f.date(2026, 9, 15), platforms: [.tiktok])
        #expect(try f.inMonthGrid(containing: f.date(2026, 9, 15)).count == 1)
    }

    @Test("a week query returns exactly that week")
    func week() throws {
        let f = try Fixture()
        try f.store.createPost(on: f.date(2026, 8, 23))  // Sunday, previous week
        try f.store.createPost(on: f.date(2026, 8, 24))  // Monday
        try f.store.createPost(on: f.date(2026, 8, 30))  // Sunday
        try f.store.createPost(on: f.date(2026, 8, 31))  // next Monday
        let posts = try f.inWeek(containing: f.date(2026, 8, 26))
        #expect(posts.map(\.day) == [f.date(2026, 8, 24), f.date(2026, 8, 30)])
    }

    @Test("a day query returns only that day")
    func day() throws {
        let f = try Fixture()
        try f.store.createPost(on: f.date(2026, 9, 3))
        try f.store.createPost(on: f.date(2026, 9, 4))
        #expect(try f.store.posts(on: f.date(2026, 9, 3)).count == 1)
    }
}

@Suite("Post display title")
@MainActor
struct PostTitleTests {

    @Test("falls back to the first caption in Platform order")
    func fallsBackToCaption() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram, .tiktok])
        try f.store.setCaption("The TikTok one", for: .tiktok, on: post)
        try f.store.setCaption("The Instagram one", for: .instagram, on: post)
        #expect(post.displayTitle(calendar: f.calendar) == "The Instagram one")
    }

    @Test("prefers the title she typed")
    func prefersExplicitTitle() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.instagram])
        try f.store.setCaption("From the caption", for: .instagram, on: post)
        try f.store.setTitle("Autumn haul", on: post)
        #expect(post.displayTitle(calendar: f.calendar) == "Autumn haul")
    }
}

@Suite("Finding a Post by its drag identifier")
@MainActor
struct PostIdentityTests {

    @Test("finds the Post that was dragged")
    func findsByIdentifier() throws {
        let f = try Fixture()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))
        try f.store.createPost(on: f.date(2026, 9, 4))
        #expect(try f.store.post(withIdentifier: post.identifier)?.day == f.date(2026, 9, 3))
    }

    @Test("returns nothing for an identifier it does not know")
    func unknownIdentifier() throws {
        let f = try Fixture()
        #expect(try f.store.post(withIdentifier: UUID()) == nil)
    }

    @Test("gives each Post its own identifier")
    func identifiersAreUnique() throws {
        let f = try Fixture()
        let a = try f.store.createPost(on: f.date(2026, 9, 3))
        let b = try f.store.createPost(on: f.date(2026, 9, 3))
        #expect(a.identifier != b.identifier)
    }
}

@Suite("Media dropped straight onto a day")
@MainActor
struct DroppedMediaTests {

    @Test("creates a Post holding what was dropped, in order")
    func createsPostFromDrop() throws {
        let f = try Fixture()
        let urls = ["a.jpg", "b.mov"].map { f.sourceFile(named: $0, contents: $0) }
        let post = try f.store.createPost(on: f.date(2026, 9, 3), importing: urls)

        #expect(post?.orderedMedia.count == 2)
        #expect(post?.orderedMedia.map(\.kind) == [.image, .video])
        #expect(try f.store.posts(on: f.date(2026, 9, 3)).count == 1)
    }

    @Test("keeps the Post when only some of the files were usable")
    func partialImport() throws {
        let f = try Fixture()
        let urls = [f.sourceFile(named: "notes.txt"), f.sourceFile(named: "clip.mov")]
        let post = try f.store.createPost(on: f.date(2026, 9, 3), importing: urls)
        #expect(post?.orderedMedia.count == 1)
    }

    @Test("leaves nothing behind when none of the files were usable")
    func nothingUsable() throws {
        let f = try Fixture()
        let urls = [f.sourceFile(named: "notes.txt"), f.sourceFile(named: "readme.md")]
        let post = try f.store.createPost(on: f.date(2026, 9, 3), importing: urls)

        #expect(post == nil)
        #expect(try f.store.posts(on: f.date(2026, 9, 3)).isEmpty, "an empty Post must not be left on the calendar")
    }

    @Test("leaves nothing behind when nothing was dropped at all")
    func emptyDrop() throws {
        let f = try Fixture()
        #expect(try f.store.createPost(on: f.date(2026, 9, 3), importing: []) == nil)
        #expect(try f.store.allPosts().isEmpty)
    }
}

@Suite("Undo")
@MainActor
struct UndoTests {

    /// Groups are opened explicitly so a test can undo exactly one edit; in the
    /// app the run loop does this per event.
    func fixtureWithUndo() throws -> (Fixture, UndoManager) {
        let f = try Fixture()
        let undo = UndoManager()
        undo.groupsByEvent = false
        f.store.undoManager = undo
        return (f, undo)
    }

    func grouped(_ undo: UndoManager, _ work: () throws -> Void) rethrows {
        undo.beginUndoGrouping()
        try work()
        undo.endUndoGrouping()
    }

    @Test("takes back an accidental reschedule")
    func undoReschedule() throws {
        let (f, undo) = try fixtureWithUndo()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))

        try grouped(undo) { try f.store.reschedule(post, to: f.date(2026, 9, 7)) }
        #expect(post.day == f.date(2026, 9, 7))

        undo.undo()
        #expect(post.day == f.date(2026, 9, 3), "a stray drag must cost her nothing")
    }

    @Test("takes back a Done tick")
    func undoDone() throws {
        let (f, undo) = try fixtureWithUndo()
        let post = try f.store.createPost(on: f.date(2026, 9, 3), platforms: [.tiktok])

        try grouped(undo) { try f.store.setDone(true, for: .tiktok, on: post) }
        #expect(post.doneState == .all)

        undo.undo()
        #expect(post.doneState == .none)
    }

    @Test("redoes what was undone")
    func redo() throws {
        let (f, undo) = try fixtureWithUndo()
        let post = try f.store.createPost(on: f.date(2026, 9, 3))

        try grouped(undo) { try f.store.reschedule(post, to: f.date(2026, 9, 7)) }
        undo.undo()
        undo.redo()
        #expect(post.day == f.date(2026, 9, 7))
    }
}

@Suite("Opening the store on disk")
@MainActor
struct StoreBootstrapTests {

    @Test("creates its directory on a first run")
    func createsMissingDirectory() throws {
        let temp = TempDirectory()
        // Nothing along this path exists yet — exactly a fresh Mac.
        let store = temp.url
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("finello", isDirectory: true)
            .appendingPathComponent("finello.store")

        _ = try PostStore.container(at: store)

        #expect(FileManager.default.fileExists(
            atPath: store.deletingLastPathComponent().path(percentEncoded: false)
        ))
    }

    @Test("a fresh store opens with no Posts in it")
    func freshStoreIsEmpty() throws {
        let temp = TempDirectory()
        let root = temp.url.appendingPathComponent("finello", isDirectory: true)
        let store = PostStore(
            container: try PostStore.container(at: root.appendingPathComponent("finello.store")),
            library: MediaLibrary(root: root.appendingPathComponent("Library", isDirectory: true))
        )
        #expect(try store.allPosts().isEmpty)
    }
}
