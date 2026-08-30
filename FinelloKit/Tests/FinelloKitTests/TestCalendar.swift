import Foundation

/// A fixed calendar so tests never depend on the machine's locale or timezone.
enum Fixed {
    static func calendar(firstWeekday: Int = 2) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = firstWeekday
        return c
    }

    static func date(_ y: Int, _ m: Int, _ d: Int, calendar: Calendar = Fixed.calendar()) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }
}
