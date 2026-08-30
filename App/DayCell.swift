import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import FinelloKit

/// One day in the month grid.
///
/// With a single Post the photo fills the cell edge to edge, because being able
/// to recognise the content at a glance is the whole reason finello exists.
/// Only three things are ever drawn over it: the day number, the done pill and
/// the overdue flag; platform badges and the media count wait for a hover.
///
/// With several Posts the cell becomes a 2×2 grid of tiles. Each tile is its
/// own click target and its own drag source, so any Post on a busy day can be
/// opened or rescheduled directly.
struct DayCell: View {
    let day: GridDay
    let posts: [Post]
    let isToday: Bool

    @Environment(AppModel.self) private var app
    @State private var isHovering = false
    @State private var isTargeted = false
    @State private var hoveredTile: PersistentIdentifier?

    /// The grid never exceeds 2×2: smaller tiles than this stop being
    /// recognisable, which defeats the point of the cell.
    private static let maxTiles = 4

    private var front: Post? { posts.first }
    private var isGrid: Bool { posts.count > 1 }
    private var visible: [Post] { Array(posts.prefix(Self.maxTiles)) }
    private var hiddenCount: Int { max(posts.count - Self.maxTiles, 0) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isGrid {
                postGrid
            } else {
                singlePost
            }
            dayNumber
            if posts.isEmpty && isHovering { addAffordance }
            if hiddenCount > 0 { morePill }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColour, lineWidth: isToday || isTargeted ? 2 : 1)
        }
        .opacity(day.isInMonth ? 1 : 0.4)
        .contentShape(.rect)
        .onHover { isHovering = $0 }
        .onTapGesture { open() }
        // In grid mode each tile is its own drag source, so the cell must not
        // also claim the gesture.
        .draggablePost(isGrid ? nil : front)
        .dayDropTarget(day: day.date, app: app, isTargeted: $isTargeted)
        .contextMenu { contextMenu }
        .help(helpText)
    }

    // MARK: Several Posts — a grid of tiles

    private var postGrid: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                tile(visible[0])
                if visible.count > 1 { tile(visible[1]) } else { emptySlot }
            }
            if visible.count > 2 {
                HStack(spacing: 2) {
                    tile(visible[2])
                    if visible.count > 3 { tile(visible[3]) } else { emptySlot }
                }
            }
        }
    }

    private var emptySlot: some View {
        Rectangle()
            .fill(Color(nsColor: .controlBackgroundColor))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tile(_ post: Post) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if let item = post.orderedMedia.first {
                MediaThumbnail(item: item)
            } else {
                ZStack {
                    Rectangle().fill(.tint.opacity(0.16))
                    Text(post.displayTitle(calendar: app.calendar))
                        .font(.system(size: 9))
                        .lineLimit(3)
                        .padding(4)
                }
            }
            tileState(post)
            if hoveredTile == post.persistentModelID { tileHoverDetail(post) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(.rect)
        .onHover { hoveredTile = $0 ? post.persistentModelID : nil }
        .onTapGesture { app.editingPost = post }
        .draggable(post.identifier.uuidString)
        .help(post.displayTitle(calendar: app.calendar))
    }

    /// A tile is too small for the `2/3` pill, so progress becomes a dot.
    @ViewBuilder
    private func tileState(_ post: Post) -> some View {
        HStack(spacing: 3) {
            if post.isOverdue(today: app.today, calendar: app.calendar) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.orange)
                    .shadow(radius: 1)
            }
            if !post.variants.isEmpty {
                Circle()
                    .fill(post.doneState.dotColour)
                    .frame(width: 8, height: 8)
                    .overlay { Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1) }
            }
        }
        .padding(4)
    }

    /// Platform badges and the carousel count, held back until hover — the same
    /// rule a single-Post cell follows, at tile scale.
    private func tileHoverDetail(_ post: Post) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 2) {
                ForEach(post.platforms, id: \.self) { platform in
                    PlatformBadge(
                        platform: platform,
                        isDone: post.variant(for: platform)?.isDone == true,
                        size: 11
                    )
                }
                if post.orderedMedia.count > 1 {
                    Text("\(post.orderedMedia.count)")
                        .font(.system(size: 9, weight: .semibold).monospacedDigit())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.thinMaterial, in: .capsule)
                }
                Spacer()
            }
            .padding(4)
        }
    }

    private var morePill: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                // Everything on the day, not only what is hidden: the menu is
                // the reliable way in when the cell is crowded.
                Menu {
                    ForEach(posts, id: \.persistentModelID) { post in
                        Button(post.displayTitle(calendar: app.calendar)) { app.editingPost = post }
                    }
                } label: {
                    Text("+\(hiddenCount)")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.thinMaterial, in: .capsule)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("\(posts.count) Posts on this day — choose one to open")
            }
        }
        .padding(5)
    }

    // MARK: A single Post — full bleed

    @ViewBuilder
    private var singlePost: some View {
        ZStack(alignment: .topLeading) {
            background
            scrim
            alwaysVisibleState
            if isHovering { hoverDetail }
        }
    }

    @ViewBuilder
    private var background: some View {
        if let front, let item = front.orderedMedia.first {
            MediaThumbnail(item: item)
        } else if let front {
            // A Post with no Media yet still has to be recognisable, so it
            // shows its own words instead.
            ZStack(alignment: .bottomLeading) {
                Rectangle().fill(.tint.opacity(0.16))
                Text(front.displayTitle(calendar: app.calendar))
                    .font(.callout)
                    .lineLimit(3)
                    .padding(8)
            }
        } else {
            Rectangle().fill(Color(nsColor: .controlBackgroundColor))
        }
    }

    private var overImage: Bool { front?.orderedMedia.isEmpty == false }

    @ViewBuilder
    private var scrim: some View {
        if overImage {
            LinearGradient(
                colors: [.black.opacity(0.55), .black.opacity(0.0), .black.opacity(0.0), .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var alwaysVisibleState: some View {
        if let front {
            VStack {
                Spacer()
                HStack(spacing: 5) {
                    Spacer()
                    if front.isOverdue(today: app.today, calendar: app.calendar) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.orange)
                            .shadow(radius: overImage ? 2 : 0)
                            .help("This day has passed with something still to publish")
                    }
                    if !front.variants.isEmpty {
                        Text("\(front.doneCount)/\(front.variants.count)")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(front.doneState.pillBackground, in: .capsule)
                            .foregroundStyle(front.doneState.pillForeground)
                    }
                }
                .padding(6)
            }
        }
    }

    @ViewBuilder
    private var hoverDetail: some View {
        if let front {
            VStack {
                Spacer()
                HStack(spacing: 3) {
                    ForEach(front.platforms, id: \.self) { platform in
                        PlatformBadge(
                            platform: platform,
                            isDone: front.variant(for: platform)?.isDone == true,
                            size: 14
                        )
                    }
                    if front.orderedMedia.count > 1 {
                        Text("\(front.orderedMedia.count)")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.thinMaterial, in: .capsule)
                            .help("\(front.orderedMedia.count) items in this carousel")
                    }
                    Spacer()
                }
                .padding(6)
            }
        }
    }

    // MARK: Chrome

    /// Over a grid the day number always needs its own backing: it can land on
    /// any tile's image.
    private var dayNumber: some View {
        let onArtwork = isGrid || overImage
        return Text("\(app.calendar.component(.day, from: day.date))")
            .font(.system(size: 13, weight: isToday ? .bold : .medium))
            .foregroundStyle(isToday ? .white : (onArtwork ? .white : .primary))
            .padding(.horizontal, isToday || onArtwork ? 6 : 0)
            .padding(.vertical, isToday || onArtwork ? 2 : 0)
            .background {
                if isToday {
                    Capsule().fill(.tint)
                } else if onArtwork {
                    Capsule().fill(.black.opacity(0.45))
                }
            }
            .padding(6)
    }

    private var addAffordance: some View {
        Image(systemName: "plus")
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var borderColour: Color {
        if isTargeted { return .accentColor }
        if isToday { return .accentColor.opacity(0.8) }
        return Color(nsColor: .separatorColor)
    }

    private var helpText: String {
        guard let front else { return "" }
        guard posts.count > 1 else { return front.displayTitle(calendar: app.calendar) }
        return "\(posts.count) Posts on this day"
    }

    private func open() {
        if let front {
            app.editingPost = front
        } else {
            app.createPost(on: day.date)
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("New Post") { app.createPost(on: day.date) }
        if !posts.isEmpty {
            Divider()
            ForEach(posts, id: \.persistentModelID) { post in
                Button("Open \(post.displayTitle(calendar: app.calendar))") { app.editingPost = post }
            }
        }
    }
}
