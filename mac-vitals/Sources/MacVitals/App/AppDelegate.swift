import AppKit
import SwiftUI
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = MetricsCoordinator()
    private var panel: WidgetPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Widget-only agent: no Dock icon, no menu-bar item (LSUIElement behaviour).
        NSApp.setActivationPolicy(.accessory)

        enableLaunchAtLogin()
        coordinator.start()
        // The widget is always on screen, so keep the adaptive samplers running.
        coordinator.uiBecameVisible()

        let hosting = NSHostingView(rootView: VitalsWidgetView(coordinator: coordinator))
        hosting.layoutSubtreeIfNeeded()
        let fitted = hosting.fittingSize
        let size = fitted.width > 0 && fitted.height > 0 ? fitted : NSSize(width: 268, height: 320)
        hosting.frame = NSRect(origin: .zero, size: size)

        let panel = WidgetPanel(contentView: hosting, size: size)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    /// Register the app to launch automatically at login (macOS 13+). Idempotent;
    /// the user can still toggle it off in System Settings › General › Login Items.
    private func enableLaunchAtLogin() {
        guard SMAppService.mainApp.status != .enabled else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("MacVitals: could not enable launch at login — \(error.localizedDescription)")
        }
    }
}
