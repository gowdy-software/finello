import SwiftUI
import FinelloKit

/// The Posts whose day has passed with something still owed. Read-only:
/// opening this never moves a date.
struct OverdueList: View {
    let posts: [Post]
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Still to publish")
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(posts, id: \.persistentModelID) { post in
                        Button {
                            app.reveal(post)
                        } label: {
                            row(post)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            .frame(maxHeight: 340)
        }
        .frame(width: 340)
    }

    private func row(_ post: Post) -> some View {
        HStack(spacing: 10) {
            if let item = post.orderedMedia.first {
                MediaThumbnail(item: item)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 44, height: 44)
                    .overlay { Image(systemName: "text.alignleft").foregroundStyle(.tertiary) }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(post.displayTitle(calendar: app.calendar))
                    .font(.callout)
                    .lineLimit(1)
                Text(dateText(post.day))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 3) {
                ForEach(post.orderedVariants.filter { !$0.isDone }.compactMap(\.platform), id: \.self) {
                    PlatformBadge(platform: $0, size: 14)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    private func dateText(_ date: Date) -> String {
        DateText.weekdayDayMonth(date, calendar: app.calendar)
    }
}
