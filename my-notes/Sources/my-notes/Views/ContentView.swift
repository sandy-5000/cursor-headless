import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(AppSettings.self) private var settings
    @Bindable var container: AppContainer
    @State private var unlockError: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var vault: VaultManager { container.vault }
    private var store: NotesStore { container.store }

    var body: some View {
        Group {
            if vault.requiresUnlock {
                UnlockView(vault: vault, store: store, unlockError: $unlockError)
            } else {
                mainView
            }
        }
        .frame(minWidth: 920, minHeight: 620)
        .tint(settings.accent)
        .preferredColorScheme(settings.preferredColorScheme)
        .onAppear {
            if !vault.requiresUnlock {
                store.prepareForUse()
            }
        }
        .onChange(of: vault.isUnlocked) { _, isUnlocked in
            if isUnlocked {
                store.prepareForUse()
            }
        }
    }

    private var mainView: some View {
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
    }
}
