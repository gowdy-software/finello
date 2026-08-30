import Foundation
import Testing
@testable import FinelloKit

@Suite("Display title")
struct TitleDerivationTests {
    let cal = Fixed.calendar()
    var day: Date { Fixed.date(2026, 3, 3, calendar: cal) }

    func derive(title: String = "", captions: [String] = []) -> String {
        TitleDerivation.displayTitle(
            title: title, captions: captions, day: day,
            calendar: cal, locale: Locale(identifier: "en_GB")
        )
    }

    @Test("uses her title when she gave one")
    func explicitTitleWins() {
        #expect(derive(title: "Autumn haul", captions: ["a caption"]) == "Autumn haul")
    }

    @Test("ignores a title that is only whitespace")
    func whitespaceTitleIgnored() {
        #expect(derive(title: "   \n ", captions: ["From the caption"]) == "From the caption")
    }

    @Test("falls back to the first non-empty caption")
    func firstCaptionUsed() {
        #expect(derive(captions: ["", "   ", "Second one counts"]) == "Second one counts")
    }

    @Test("uses only the first line of a multi-line caption")
    func firstLineOnly() {
        #expect(derive(captions: ["Morning routine\n\n#skincare #grwm"]) == "Morning routine")
    }

    @Test("truncates a long caption on a word boundary")
    func truncatesOnWordBoundary() {
        let long = "This is a really quite long opening line that will not fit in a title"
        let result = derive(captions: [long])
        #expect(result.hasSuffix("…"))
        #expect(result.count <= TitleDerivation.captionLimit + 1)
        #expect(!result.dropLast().hasSuffix(" "))
        #expect(long.hasPrefix(String(result.dropLast())))
    }

    @Test("falls back to the date when there is no title and no caption")
    func dateFallback() {
        #expect(derive() == "Post on 3 March")
    }

    @Test("falls back to the date when every caption is blank")
    func allCaptionsBlank() {
        #expect(derive(captions: ["", "  ", "\n"]) == "Post on 3 March")
    }
}

@Suite("Poster frame offset")
struct PosterFrameTests {

    @Test("lands a second in for an ordinary clip")
    func ordinaryClip() {
        #expect(PosterFrame.offset(forDuration: 58) == 1.0)
    }

    @Test("never seeks past the end of a very short clip")
    func shortClip() {
        #expect(PosterFrame.offset(forDuration: 0.4) == 0.2)
        #expect(PosterFrame.offset(forDuration: 1.5) == 0.75)
    }

    @Test("is never frame zero for a clip with any duration", arguments: [0.1, 0.5, 2.0, 30.0, 600.0])
    func neverFrameZero(duration: TimeInterval) {
        #expect(PosterFrame.offset(forDuration: duration) > 0)
    }

    @Test("copes with an unreadable duration", arguments: [0.0, -1.0, TimeInterval.infinity, TimeInterval.nan])
    func degenerateDuration(duration: TimeInterval) {
        #expect(PosterFrame.offset(forDuration: duration) == 0)
    }
}
