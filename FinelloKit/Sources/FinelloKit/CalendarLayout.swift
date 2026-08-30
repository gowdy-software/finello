import Foundation

/// One cell in a month grid: a date, and whether it belongs to the month
/// being displayed or is a leading/trailing day borrowed from a neighbour.
public struct GridDay: Hashable, Sendable {
    public let date: Date
    public let isInMonth: Bool

    public init(date: Date, isInMonth: Bool) {
        self.date = date
        self.isInMonth = isInMonth
    }
}

/// Pure date arithmetic for the calendar views. Has no dependencies and never
/// reads the current time, so every result is a function of its arguments.
public struct CalendarLayout: Sendable {
    public let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    public func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    /// The days of a month grid: leading days from the previous month, every
    /// day of this month, and trailing days to complete the final week. Always
    /// a whole number of weeks, so the grid is a complete rectangle.
    public func monthGrid(containing date: Date) -> [GridDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let firstOfMonth = monthInterval.start

        // Back up to the start of the week containing the 1st.
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: firstOfMonth) else { return [] }

        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 0
        let total = Int((Double(leading + daysInMonth) / 7.0).rounded(.up)) * 7

        return (0..<total).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            let inMonth = calendar.isDate(day, equalTo: firstOfMonth, toGranularity: .month)
            return GridDay(date: startOfDay(day), isInMonth: inMonth)
        }
    }

    /// The seven days of the week containing `date`, starting on the calendar's
    /// first weekday.
    public func week(containing date: Date) -> [Date] {
        let day = startOfDay(date)
        let weekday = calendar.component(.weekday, from: day)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: -offset, to: day) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// The half-open range of days covered by the month grid containing `date`,
    /// used to fetch exactly the Posts a month view can display.
    public func monthGridRange(containing date: Date) -> Range<Date>? {
        let grid = monthGrid(containing: date)
        guard let first = grid.first?.date, let last = grid.last?.date,
              let end = calendar.date(byAdding: .day, value: 1, to: last) else { return nil }
        return first..<end
    }

    public func weekRange(containing date: Date) -> Range<Date>? {
        let days = week(containing: date)
        guard let first = days.first, let last = days.last,
              let end = calendar.date(byAdding: .day, value: 1, to: last) else { return nil }
        return first..<end
    }
}
