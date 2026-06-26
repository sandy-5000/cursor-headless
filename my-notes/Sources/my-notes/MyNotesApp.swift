import SwiftUI

@main
struct MyNotesApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .preferredColorScheme(settings.preferredColorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 720)

        Settings {
            SettingsView()
                .environment(settings)
                .preferredColorScheme(settings.preferredColorScheme)
        }
    }
}
