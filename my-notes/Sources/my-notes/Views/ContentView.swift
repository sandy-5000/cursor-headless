import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(AppSettings.self) private var settings
    @State private var store = NotesStore()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 460)
        } detail: {
            NoteEditorView(store: store)
        }
        .navigationSplitViewStyle(.balanced)
        .background {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .controlBackgroundColor).opacity(0.65),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .frame(minWidth: 920, minHeight: 620)
        .tint(settings.accent)
    }
}
