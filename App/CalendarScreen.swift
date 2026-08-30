import SwiftUI
import SwiftData
import FinelloKit

struct CalendarScreen: View {
    @Environment(AppModel.self) private var app

    // Deliberately unfiltered: at a few hundred Posts a year this is cheap,
    // and it means every view updates itself whenever the Store writes.
    @Query(sort: [SortDescriptor(\Post.day), SortDescriptor(\Post.createdAt)])
    private var allPosts: [Post]

    var body: some View {
        @Bindable var app = app

        VStack(spacing: 0) {
            if let warning = app.startupWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.yellow.opacity(0.25))
            }

            switch app.mode {
            case .month: MonthView(posts: allPosts)
            case .week: WeekView(posts: allPosts)
            }
        }
        .navigationTitle("finello")
        .navigationSubtitle(app.periodTitle)
        .toolbar { toolbar }
        .sheet(item: $app.editingPost) { post in
            PostEditor(post: post)
                .environment(app)
        }
    }

    private var overdue: [Post] { app.overdue(within: allPosts) }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        @Bindable var app = app

        ToolbarItemGroup(placement: .navigation) {
            Button { app.step(-1) } label: { Image(systemName: "chevron.left") }
                .help("Previous")
            Button("Today") { app.goToToday() }
            Button { app.step(1) } label: { Image(systemName: "chevron.right") }
                .help("Next")
        }

        ToolbarItem(placement: .principal) {
            Picker("View", selection: $app.mode) {
                ForEach(CalendarMode.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }

        ToolbarItemGroup(placement: .primaryAction) {
            if !overdue.isEmpty {
                Button {
                    app.showingOverdue = true
                } label: {
                    Label("\(overdue.count) overdue", systemImage: "exclamationmark.triangle.fill")
                }
                .tint(.orange)
                .help("\(overdue.count) Posts whose day has passed with something still to publish")
                .popover(isPresented: $app.showingOverdue, arrowEdge: .bottom) {
                    OverdueList(posts: overdue)
                        .environment(app)
                }
            }
            Button {
                app.createPost(on: app.mode == .month ? app.today : app.anchor)
            } label: {
                Label("New Post", systemImage: "plus")
            }
        }
    }
}
