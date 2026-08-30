import Foundation
import Testing
@testable import FinelloKit

@Suite("Month grid")
struct MonthGridTests {

    @Test("is always a whole number of weeks", arguments: [
        (2024, 1), (2024, 2), (2024, 9), (2025, 2), (2025, 3), (2026, 8), (2027, 5),
    ])
    func wholeWeeks(year: Int, month: Int) {
        let cal = Fixed.calendar()
        let layout = CalendarLayout(calendar: cal)
        let grid = layout.monthGrid(containing: Fixed.date(year, month, 1, calendar: cal))
        #expect(grid.count % 7 == 0)
        #expect(grid.count >= 28)
    }

    @Test("contains every day of the month exactly once, marked in-month")
    func containsWholeMonth() {
        let cal = Fixed.calendar()
        let layout = CalendarLayout(calendar: cal)
        let grid = layout.monthGrid(containing: Fixed.date(2024, 2, 15, calendar: cal))
        let inMonth = grid.filter(\.isInMonth)
        #expect(inMonth.count == 29, "February 2024 is a leap February")
        #expect(Set(inMonth.map(\.date)).count == 29)
    }

    @Test("a non-leap February has 28 in-month days")
    func nonLeapFebruary() {
        let cal = Fixed.calendar()
        let layout = CalendarLayout(calendar: cal)
        let grid = layout.monthGrid(containing: Fixed.date(2025, 2, 10, calendar: cal))
        #expect(grid.filter(\.isInMonth).count == 28)
    }

    @Test("leading and trailing days are marked out-of-month")
    func neighbouringDaysMarked() {
        let cal = Fixed.calendar()
        let layout = CalendarLayout(calendar: cal)
        let grid = layout.monthGrid(containing: Fixed.date(2026, 8, 1, calendar: cal))
        let firstOfMonth = Fixed.date(2026, 8, 1, calendar: cal)
        for day in grid where day.date < firstOfMonth {
            #expect(day.isInMonth == false)
        }
    }

    @Test("starts on the calendar's first weekday", arguments: [1, 2])
    func startsOnFirstWeekday(firstWeekday: Int) {
        let cal = Fixed.calendar(firstWeekday: firstWeekday)
        let layout = CalendarLayout(calendar: cal)
        let grid = layout.monthGrid(containing: Fixed.date(2026, 8, 20, calendar: cal))
        let weekdayOfFirstCell = cal.component(.weekday, from: grid[0].date)
        #expect(weekdayOfFirstCell == firstWeekday)
    }

    @Test("has no leading days when the month starts on the first weekday")
    func noLeadingDaysWhenAligned() {
        // 1 June 2026 is a Monday; with firstWeekday = Monday the grid starts there.
        let cal = Fixed.calendar(firstWeekday: 2)
        let layout = CalendarLayout(calendar: cal)
        let grid = layout.monthGrid(containing: Fixed.date(2026, 6, 1, calendar: cal))
        #expect(grid[0].date == Fixed.date(2026, 6, 1, calendar: cal))
        #expect(grid[0].isInMonth)
    }
}

@Suite("Week")
struct WeekTests {

    @Test("is seven consecutive days starting on the first weekday")
    func sevenDays() {
        let cal = Fixed.calendar(firstWeekday: 2)
        let layout = CalendarLayout(calendar: cal)
        // 26 August 2026 is a Wednesday.
        let days = layout.week(containing: Fixed.date(2026, 8, 26, calendar: cal))
        #expect(days.count == 7)
        #expect(days.first == Fixed.date(2026, 8, 24, calendar: cal))
        #expect(days.last == Fixed.date(2026, 8, 30, calendar: cal))
    }

    @Test("a week spanning a month boundary still returns seven days")
    func acrossMonthBoundary() {
        let cal = Fixed.calendar(firstWeekday: 2)
        let layout = CalendarLayout(calendar: cal)
        let days = layout.week(containing: Fixed.date(2026, 8, 31, calendar: cal))
        #expect(days.count == 7)
        #expect(days.first == Fixed.date(2026, 8, 31, calendar: cal))
        #expect(days.last == Fixed.date(2026, 9, 6, calendar: cal))
    }

    @Test("week range covers the whole week and no more")
    func weekRange() {
        let cal = Fixed.calendar(firstWeekday: 2)
        let layout = CalendarLayout(calendar: cal)
        let range = layout.weekRange(containing: Fixed.date(2026, 8, 26, calendar: cal))
        #expect(range?.lowerBound == Fixed.date(2026, 8, 24, calendar: cal))
        #expect(range?.upperBound == Fixed.date(2026, 8, 31, calendar: cal))
    }
}
