import SwiftUI
import SwiftData
import FinelloKit

@main
struct FinelloApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            CalendarScreen()
                .environment(app)
                .frame(minWidth: 900, minHeight: 620)
        }
        .modelContainer(app.store.container)
        .defaultSize(width: 1240, height: 840)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { app.undoManager.undo() }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(!app.undoManager.canUndo)
                Button("Redo") { app.undoManager.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!app.undoManager.canRedo)
            }
            CommandGroup(after: .newItem) {
                Button("New Post Today") { app.createPost(on: app.today) }
                    .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                Picker("View", selection: Binding(get: { app.mode }, set: { app.mode = $0 })) {
                    ForEach(CalendarMode.allCases) { Text($0.label).tag($0) }
                }
                Button("Today") { app.goToToday() }
                    .keyboardShortcut("t", modifiers: .command)
                Button("Previous") { app.step(-1) }
                    .keyboardShortcut(.leftArrow, modifiers: .command)
                Button("Next") { app.step(1) }
                    .keyboardShortcut(.rightArrow, modifiers: .command)
                Divider()
                Button("Reveal Library in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([app.store.library.root])
                }
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { app.updates.checkForUpdates() }
                    .disabled(!app.updates.canCheckForUpdates)
            }
        }
    }
}
