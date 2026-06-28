import SwiftUI

@main
struct MacVitalsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No window/menu-bar scene: the widget itself is a borderless panel that
        // the AppDelegate creates and owns. `Settings` gives the App a valid (but
        // hidden) scene without putting anything in the menu bar or Dock.
        Settings { EmptyView() }
    }
}
