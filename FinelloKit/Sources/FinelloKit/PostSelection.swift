import Foundation

/// Choosing which Posts a view shows.
///
/// The calendar reads Posts through SwiftUI's `@Query` so the interface updates
/// itself whenever the Store writes — which means the selection happens in
/// memory rather than in a fetch predicate. Keeping that selection here rather
/// than in the views means the shipping read path is the tested one, instead of
/// a second copy that can drift from the Store's.
///
/// At a few hundred Posts a year, filtering an array costs nothing.
@MainActor
public enum PostSelection {
    public static func posts(on day: Date, in posts: [Post], calendar: Calendar) -> [Post] {
        posts.filter { calendar.isDate($0.day, inSameDayAs: day) }
    }

    /// Posts whose day has passed with something still owed, oldest first.
    /// Read-only: nothing here touches a date.
    public static func overdue(in posts: [Post], today: Date, calendar: Calendar) -> [Post] {
        posts
            .filter { $0.isOverdue(today: today, calendar: calendar) }
            .sorted { ($0.day, $0.createdAt) < ($1.day, $1.createdAt) }
    }
}
