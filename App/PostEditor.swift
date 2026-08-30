import SwiftUI
import UniformTypeIdentifiers
import FinelloKit

/// One Post, with a tab per Platform it targets.
///
/// Tabs rather than a stack, because she is not comparing captions
/// side by side — she is deriving the short ones from the long one, which
/// "copy from" serves better than a taller page would.
struct PostEditor: View {
    let post: Post

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Platform?
    @State private var importingMedia = false
    @State private var confirmingDelete = false
    @State private var platformPendingRemoval: Platform?
    @State private var mediaPendingRemoval: Int?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    mediaSection
                    platformSection
                    if let platform = activePlatform {
                        variantSection(platform)
                    } else {
                        ContentUnavailableView(
                            "No platforms yet",
                            systemImage: "square.grid.2x2",
                            description: Text("Pick where this is going and a tab appears for each one.")
                        )
                        .frame(height: 160)
                    }
                }
                .padding(18)
            }
        }
        .frame(width: 720, height: 700)
        .onAppear { selected = post.platforms.first }
        .confirmationDialog(
            "Delete this Post?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Post and \(post.orderedMedia.count) Media", role: .destructive) {
                try? app.store.delete(post)
                dismiss()
            }
        } message: {
            Text("finello holds the only copy of this Media if you have deleted the originals. This cannot be undone.")
        }
        .confirmationDialog(
            "Remove \(platformPendingRemoval?.displayName ?? "")?",
            isPresented: Binding(
                get: { platformPendingRemoval != nil },
                set: { if !$0 { platformPendingRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove and discard the writing", role: .destructive) {
                if let platform = platformPendingRemoval {
                    apply(removing: platform)
                }
                platformPendingRemoval = nil
            }
        } message: {
            Text("You have already written something for this platform. Removing it discards that.")
        }
        .confirmationDialog(
            "Remove this Media?",
            isPresented: Binding(
                get: { mediaPendingRemoval != nil },
                set: { if !$0 { mediaPendingRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let index = mediaPendingRemoval, post.orderedMedia.indices.contains(index) {
                    let filename = post.orderedMedia[index].filename
                    try? app.store.removeMedia(at: index, from: post)
                    app.thumbnails.forget(filename)
                }
                mediaPendingRemoval = nil
            }
        } message: {
            Text("This deletes the file from finello's Library. If you have already deleted the original, this is the only copy and it cannot be undone.")
        }
        .fileImporter(
            isPresented: $importingMedia,
            allowedContentTypes: [.image, .movie, .audio],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            let scoped = urls.filter { $0.startAccessingSecurityScopedResource() }
            defer { scoped.forEach { $0.stopAccessingSecurityScopedResource() } }
            _ = try? app.store.addMedia(from: urls, to: post)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            TextField(
                "Title",
                text: Binding(
                    get: { post.title },
                    set: { try? app.store.setTitle($0, on: post) }
                ),
                prompt: Text(post.displayTitle(calendar: app.calendar))
            )
            .textFieldStyle(.plain)
            .font(.title3.weight(.semibold))

            DatePicker(
                "",
                selection: Binding(
                    get: { post.day },
                    set: { try? app.store.reschedule(post, to: $0) }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .fixedSize()

            Button(role: .destructive) {
                confirmingDelete = true
            } label: {
                Image(systemName: "trash")
            }
            .help("Delete this Post")

            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    // MARK: Media

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Media", detail: mediaDetail)

            if post.orderedMedia.isEmpty {
                dropWell
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(Array(post.orderedMedia.enumerated()), id: \.element.persistentModelID) { index, item in
                            mediaTile(item, at: index)
                        }
                        addTile
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            ((try? app.store.addMedia(from: urls, to: post)) ?? 0) > 0
        }
    }

    private var mediaDetail: String? {
        let count = post.orderedMedia.count
        guard count > 1 else { return nil }
        return "\(count) items — drag to set the carousel order"
    }

    /// The drop zone is also the add button: click it to choose files, or drop
    /// them on it. There is no separate control.
    private var dropWell: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .frame(height: 110)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle.angled").font(.title2)
                    Text("Click to choose photos, video or audio").font(.caption)
                    Text("or drop them here").font(.caption2).foregroundStyle(.tertiary)
                }
                .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
            .onTapGesture { importingMedia = true }
            .help("Click to choose files, or drop them here")
    }

    private var addTile: some View {
        RoundedRectangle(cornerRadius: 6)
            .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
            .frame(width: 118, height: 118)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "plus").font(.title3)
                    Text("Add").font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
            .onTapGesture { importingMedia = true }
            .help("Click to choose more files, or drop them here")
    }

    private func mediaTile(_ item: MediaItem, at index: Int) -> some View {
        MediaThumbnail(item: item)
            .frame(width: 118, height: 118)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .topTrailing) {
                Button {
                    mediaPendingRemoval = index
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .font(.body)
                }
                .buttonStyle(.plain)
                .padding(4)
            }
            .overlay(alignment: .bottomLeading) {
                if index == 0 && post.orderedMedia.count > 1 {
                    Text("First")
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(.thinMaterial, in: .capsule)
                        .padding(4)
                }
            }
            .draggable(item.filename)
            .dropDestination(for: String.self) { payload, _ in
                guard let filename = payload.first,
                      let from = post.orderedMedia.firstIndex(where: { $0.filename == filename })
                else { return false }
                try? app.store.moveMedia(on: post, from: from, to: index)
                return true
            }
    }

    // MARK: Platforms

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Platforms", detail: "Only the ones you pick get a tab")
            HStack(spacing: 8) {
                ForEach(Platform.allCases) { platform in
                    platformChip(platform)
                }
                Spacer()
            }
        }
    }

    private func platformChip(_ platform: Platform) -> some View {
        let isOn = post.variant(for: platform) != nil
        return Button {
            toggle(platform)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: platform.symbolName)
                Text(platform.displayName)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isOn ? platform.tint : Color.secondary.opacity(0.12), in: .capsule)
            .foregroundStyle(isOn ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: One Platform's writing

    private var activePlatform: Platform? {
        if let selected, post.variant(for: selected) != nil { return selected }
        return post.platforms.first
    }

    @ViewBuilder
    private func variantSection(_ platform: Platform) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: Binding(get: { platform }, set: { selected = $0 })) {
                ForEach(post.platforms, id: \.self) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            HStack {
                Toggle(isOn: Binding(
                    get: { post.variant(for: platform)?.isDone ?? false },
                    set: { try? app.store.setDone($0, for: platform, on: post) }
                )) {
                    Text("Done on \(platform.displayName)")
                }
                .toggleStyle(.checkbox)

                Spacer()

                if post.platforms.count > 1 {
                    Menu("Copy from…") {
                        ForEach(post.platforms.filter { $0 != platform }, id: \.self) { source in
                            Button(source.displayName) {
                                try? app.store.copyWriting(from: source, to: platform, on: post)
                            }
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Start from another platform's wording and cut it down")
                }
            }

            field("Caption", height: 130, text: Binding(
                get: { post.variant(for: platform)?.caption ?? "" },
                set: { try? app.store.setCaption($0, for: platform, on: post) }
            ))

            field("Description", height: 90, text: Binding(
                get: { post.variant(for: platform)?.descriptionText ?? "" },
                set: { try? app.store.setDescription($0, for: platform, on: post) }
            ))

            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Hashtags")
                TextField("#hashtags", text: Binding(
                    get: { post.variant(for: platform)?.hashtags ?? "" },
                    set: { try? app.store.setHashtags($0, for: platform, on: post) }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func field(_ title: String, height: CGFloat, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(title)
            TextEditor(text: text)
                .font(.body)
                .frame(height: height)
                .padding(4)
                .background(.background.secondary, in: .rect(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(.separator, lineWidth: 1)
                }
        }
    }

    // MARK: Editing platforms

    private func toggle(_ platform: Platform) {
        if post.variant(for: platform) == nil {
            var platforms = post.platforms
            platforms.append(platform)
            try? app.store.setPlatforms(platforms, on: post)
            selected = platform
        } else if app.store.platformsWithWriting([platform], on: post).isEmpty {
            apply(removing: platform)
        } else {
            platformPendingRemoval = platform
        }
    }

    private func apply(removing platform: Platform) {
        let remaining = post.platforms.filter { $0 != platform }
        try? app.store.setPlatforms(remaining, on: post)
        if selected == platform { selected = remaining.first }
    }
}

private struct SectionLabel: View {
    let title: String
    var detail: String?

    init(_ title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let detail {
                Text(detail).font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}
