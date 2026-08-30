import Foundation

/// Localised date strings for the calendar chrome.
///
/// `DateFormatter` is expensive to build and was being rebuilt on every render
/// in four different views. These are made once and reused.
@MainActor
enum DateText {
    private static var cache: [String: DateFormatter] = [:]

    private static func formatter(template: String, calendar: Calendar) -> DateFormatter {
        let key = "\(template)|\(calendar.identifier)|\(calendar.timeZone.identifier)"
        if let hit = cache[key] { return hit }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        cache[key] = formatter
        return formatter
    }

    static func monthAndYear(_ date: Date, calendar: Calendar) -> String {
        formatter(template: "MMMM yyyy", calendar: calendar).string(from: date)
    }

    static func dayAndMonth(_ date: Date, calendar: Calendar) -> String {
        formatter(template: "d MMM", calendar: calendar).string(from: date)
    }

    static func weekdayDayMonth(_ date: Date, calendar: Calendar) -> String {
        formatter(template: "EEE d MMM", calendar: calendar).string(from: date)
    }

    static func weekday(_ date: Date, calendar: Calendar) -> String {
        formatter(template: "EEE", calendar: calendar).string(from: date)
    }

    /// Weekday initials rotated to start on the calendar's first weekday.
    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = formatter(template: "EEE", calendar: calendar).shortWeekdaySymbols
            ?? ["S", "M", "T", "W", "T", "F", "S"]
        let first = calendar.firstWeekday - 1
        guard symbols.indices.contains(first) else { return symbols }
        return Array(symbols[first...] + symbols[..<first])
    }
}
