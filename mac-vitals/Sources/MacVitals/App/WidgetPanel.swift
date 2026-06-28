import AppKit

/// A borderless, translucent, draggable panel that behaves like a desktop widget.
///
/// It joins all Spaces, is moved by dragging its background, and never steals
/// focus from the app you're working in (`.nonactivatingPanel`) — yet still lets
/// its buttons receive clicks (`canBecomeKey`).
///
/// Moving the widget:
///   • Drag it by its background (reveal the desktop first, since it sits behind apps).
///   • Its position is remembered across launches.
///   • Launch with `--corner topLeft|topRight|bottomLeft|bottomRight` to snap it,
///     e.g. `open -a MacVitals --args --corner topRight`.
final class WidgetPanel: NSPanel {
    private let originDefaultsKey = "WidgetOriginV3"
    private let edgeMargin: CGFloat = 8

    init(contentView: NSView, size: NSSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Sit on the desktop, behind every app window (above the wallpaper/icons
        // but below all normal app windows) — a true desktop widget.
        isFloatingPanel = false
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        animationBehavior = .none

        self.contentView = contentView
        applyInitialPosition()

        // Remember wherever the user drags it.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveOrigin),
            name: NSWindow.didMoveNotification,
            object: self
        )
    }

    // MARK: - Positioning

    enum Corner: String {
        case topLeft, topRight, bottomLeft, bottomRight

        static func fromArguments() -> Corner? {
            let args = CommandLine.arguments
            guard let idx = args.firstIndex(of: "--corner"), idx + 1 < args.count else { return nil }
            return Corner(rawValue: args[idx + 1])
        }
    }

    private func applyInitialPosition() {
        // 1) An explicit corner from launch args wins (and is persisted).
        if let corner = Corner.fromArguments() {
            move(to: corner)
            return
        }
        // 2) Otherwise restore the last dragged position, if any.
        if let saved = UserDefaults.standard.string(forKey: originDefaultsKey) {
            setFrameOrigin(clampedToScreen(NSPointFromString(saved)))
            return
        }
        // 3) First run: default to top-left.
        move(to: .topLeft)
    }

    /// Snap the widget to a screen corner and remember it.
    func move(to corner: Corner) {
        guard let visible = (screen ?? NSScreen.main)?.visibleFrame else { return }
        let m = edgeMargin
        let x: CGFloat
        let y: CGFloat
        switch corner {
        case .topLeft:     x = visible.minX + m;                    y = visible.maxY - frame.height - m
        case .topRight:    x = visible.maxX - frame.width - m;      y = visible.maxY - frame.height - m
        case .bottomLeft:  x = visible.minX + m;                    y = visible.minY + m
        case .bottomRight: x = visible.maxX - frame.width - m;      y = visible.minY + m
        }
        setFrameOrigin(NSPoint(x: x, y: y))
        saveOrigin()
    }

    private func clampedToScreen(_ origin: NSPoint) -> NSPoint {
        guard let visible = (screen ?? NSScreen.main)?.visibleFrame else { return origin }
        let x = min(max(origin.x, visible.minX), visible.maxX - frame.width)
        let y = min(max(origin.y, visible.minY), visible.maxY - frame.height)
        return NSPoint(x: x, y: y)
    }

    @objc private func saveOrigin() {
        UserDefaults.standard.set(NSStringFromPoint(frame.origin), forKey: originDefaultsKey)
    }

    // Borderless panels can't become key by default; allow it so SwiftUI controls
    // (the Quit button) stay clickable.
    override var canBecomeKey: Bool { true }
}
