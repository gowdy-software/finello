import Foundation

/// How a Post decides what to call itself. Pure, so that the rule can be
/// tested without building a Post.
public enum TitleDerivation {
    public static let captionLimit = 40

    /// The Post's own title if she gave it one; otherwise the opening of the
    /// first non-empty caption; otherwise a date-based fallback. She never has
    /// to type a title, but always sees a sensible one.
    public static func displayTitle(
        title: String,
        captions: [String],
        day: Date,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let trimmedTitle = title.trimmed
        if !trimmedTitle.isEmpty { return trimmedTitle }

        for caption in captions {
            let opening = firstLine(of: caption)
            if !opening.isEmpty { return truncate(opening, to: captionLimit) }
        }

        return dateFallback(for: day, calendar: calendar, locale: locale)
    }

    static func firstLine(of caption: String) -> String {
        caption
            .split(whereSeparator: \.isNewline)
            .first
            .map { String($0).trimmed } ?? ""
    }

    /// Truncates on a word boundary where possible, so a title never ends
    /// mid-word.
    static func truncate(_ text: String, to limit: Int) -> String {
        guard text.count > limit else { return text }
        let clipped = String(text.prefix(limit))
        if let lastSpace = clipped.lastIndex(of: " "), lastSpace > clipped.startIndex {
            return String(clipped[clipped.startIndex..<lastSpace]).trimmed + "…"
        }
        return clipped.trimmed + "…"
    }

    static func dateFallback(for day: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return "Post on \(formatter.string(from: day))"
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
