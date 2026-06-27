import SwiftUI

@main
struct MyNotesApp: App {
    @State private var settings = AppSettings()
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
                .environment(settings)
                .preferredColorScheme(settings.preferredColorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 720)

        Settings {
            EncryptionSettingsView(container: container, settings: settings)
                .preferredColorScheme(settings.preferredColorScheme)
        }
    }
}
