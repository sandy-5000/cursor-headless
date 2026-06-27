import AppKit

enum BrowserOption: String, CaseIterable, Identifiable, Codable {
    case systemDefault
    case safari
    case chrome
    case firefox
    case arc
    case brave
    case edge
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .systemDefault: "System Default"
        case .safari: "Safari"
        case .chrome: "Google Chrome"
        case .firefox: "Firefox"
        case .arc: "Arc"
        case .brave: "Brave"
        case .edge: "Microsoft Edge"
        case .custom: "Custom App…"
        }
    }

    var bundlePath: String? {
        switch self {
        case .systemDefault, .custom: nil
        case .safari: "/Applications/Safari.app"
        case .chrome: "/Applications/Google Chrome.app"
        case .firefox: "/Applications/Firefox.app"
        case .arc: "/Applications/Arc.app"
        case .brave: "/Applications/Brave Browser.app"
        case .edge: "/Applications/Microsoft Edge.app"
        }
    }

    var isInstalled: Bool {
        guard let bundlePath else { return true }
        return FileManager.default.fileExists(atPath: bundlePath)
    }

    static var selectableOptions: [BrowserOption] {
        allCases.filter { $0 == .systemDefault || $0 == .custom || $0.isInstalled }
    }
}

@MainActor
enum BrowserLauncher {
    static func open(_ url: URL, browser: BrowserOption, customBrowserPath: String?) {
        if let appURL = browserAppURL(browser: browser, customBrowserPath: customBrowserPath) {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { _, error in
                if error != nil {
                    NSWorkspace.shared.open(url)
                }
            }
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    static func browserAppURL(browser: BrowserOption, customBrowserPath: String?) -> URL? {
        switch browser {
        case .systemDefault:
            return nil
        case .custom:
            guard let customBrowserPath, !customBrowserPath.isEmpty else { return nil }
            let url = URL(fileURLWithPath: customBrowserPath)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        default:
            guard let bundlePath = browser.bundlePath else { return nil }
            let url = URL(fileURLWithPath: bundlePath)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
    }

    static func displayName(for browser: BrowserOption, customBrowserPath: String?) -> String {
        if browser == .custom, let customBrowserPath, !customBrowserPath.isEmpty {
            return URL(fileURLWithPath: customBrowserPath).deletingPathExtension().lastPathComponent
        }
        return browser.label
    }
}
