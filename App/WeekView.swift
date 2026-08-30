import SwiftUI
import FinelloKit

/// The writing view. Seven tall columns, so there is room for large Media,
/// a readable caption and per-Platform Done toggles without opening anything.
struct WeekView: View {
    let posts: [Post]
    @Environment(AppModel.self) private var app

    var body: some View {
        HStack(spacing: 8) {
            ForEach(app.layout.week(containing: app.anchor), id: \.self) { day in
                WeekColumn(day: day, posts: app.posts(on: day, within: posts))
            }
        }
        .padding(12)
    }
}

private struct WeekColumn: View {
    let day: Date
    let posts: [Post]

    @Environment(AppModel.self) private var app
    @State private var isTargeted = false

    private var isToday: Bool { app.calendar.isDate(day, inSameDayAs: app.today) }

    var body: some View {
        VStack(spacing: 8) {
            header
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(posts, id: \.persistentModelID) { post in
                        WeekPostCard(post: post)
                    }
                    Button {
                        app.createPost(on: day)
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background(.background.secondary, in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isTargeted ? Color.accentColor : .clear, lineWidth: 2)
        }
        .dayDropTarget(day: day, app: app, isTargeted: $isTargeted)
    }

    private var header: some View {
        VStack(spacing: 1) {
            Text(weekdayName.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(app.calendar.component(.day, from: day))")
                .font(.title3.weight(isToday ? .bold : .regular))
                .foregroundStyle(isToday ? Color.accentColor : .primary)
        }
    }

    private var weekdayName: String { DateText.weekday(day, calendar: app.calendar) }
}

private struct WeekPostCard: View {
    let post: Post
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let item = post.orderedMedia.first {
                MediaThumbnail(item: item)
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Text(post.displayTitle(calendar: app.calendar))
                .font(.caption.weight(.semibold))
                .lineLimit(2)

            if let caption = firstCaption, !caption.isEmpty {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            if post.isOverdue(today: app.today, calendar: app.calendar) {
                Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            // Ticking off from here is the point of the week view: recording
            // that something went out should not need the editor.
            HStack(spacing: 4) {
                ForEach(post.platforms, id: \.self) { platform in
                    Button {
                        try? app.store.toggleDone(for: platform, on: post)
                    } label: {
                        PlatformBadge(
                            platform: platform,
                            isDone: post.variant(for: platform)?.isDone == true,
                            size: 18
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: .rect(cornerRadius: 8))
        .contentShape(.rect)
        .onTapGesture { app.editingPost = post }
        .draggable(post.identifier.uuidString)
        .contextMenu {
            Button("Open") { app.editingPost = post }
        }
    }

    private var firstCaption: String? {
        post.orderedVariants.map(\.caption).first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
