import AppKit
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable, Codable {
    case blue
    case teal
    case amber
    case rose
    case green
    case violet

    var id: String { rawValue }

    var label: String {
        switch self {
            case .blue: "Blue"
            case .teal: "Teal"
            case .amber: "Amber"
            case .rose: "Rose"
            case .green: "Green"
            case .violet: "Violet"
        }
    }

    var color: Color {
        switch self {
            case .blue: Color(red: 0.42, green: 0.55, blue: 0.98)
            case .teal: Color(red: 0.18, green: 0.68, blue: 0.64)
            case .amber: Color(red: 0.94, green: 0.62, blue: 0.18)
            case .rose: Color(red: 0.91, green: 0.38, blue: 0.52)
            case .green: Color(red: 0.32, green: 0.72, blue: 0.44)
            case .violet: Color(red: 0.56, green: 0.42, blue: 0.96)
        }
    }
}

@MainActor
@Observable
final class AppSettings {
    static let titleFontSizeRange: ClosedRange<Double> = 24...48
    static let contentFontSizeRange: ClosedRange<Double> = 12...24

    var accentColor: AccentColorOption {
        didSet { persist() }
    }

    var appearanceMode: AppearanceMode {
        didSet { persist() }
    }

    var titleFontSize: Double {
        didSet { persist() }
    }

    var contentFontSize: Double {
        didSet { persist() }
    }

    var browserOption: BrowserOption {
        didSet { persist() }
    }

    var customBrowserPath: String {
        didSet { persist() }
    }

    var accent: Color { accentColor.color }

    var accentSoft: Color { accentColor.color.opacity(0.14) }

    var preferredColorScheme: ColorScheme? { appearanceMode.colorScheme }

    var browserDisplayName: String {
        BrowserLauncher.displayName(for: browserOption, customBrowserPath: customBrowserPath)
    }

    func openLink(_ url: URL) {
        BrowserLauncher.open(url, browser: browserOption, customBrowserPath: customBrowserPath)
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    func titleFont() -> Font {
        font(size: titleFontSize, weight: .semibold)
    }

    func bodyFont() -> Font {
        font(size: contentFontSize, weight: .regular)
    }

    func captionFont(size: CGFloat? = nil) -> Font {
        font(size: size ?? max(contentFontSize - 2, 12), weight: .medium)
    }

    func sidebarHeaderFont() -> Font {
        font(size: contentFontSize + 2, weight: .semibold)
    }

    func sidebarTitleFont() -> Font {
        font(size: contentFontSize, weight: .semibold)
    }

    func sidebarPreviewFont() -> Font {
        font(size: max(contentFontSize - 1, 12))
    }

    func sidebarCaptionFont() -> Font {
        font(size: max(contentFontSize - 2, 12), weight: .medium)
    }

    init(userDefaults: UserDefaults = .standard) {
        let storedAccent = userDefaults.string(forKey: Keys.accentColor)
        accentColor = AccentColorOption(rawValue: storedAccent ?? "") ?? .blue

        let storedAppearance = userDefaults.string(forKey: Keys.appearanceMode)
        appearanceMode = AppearanceMode(rawValue: storedAppearance ?? "") ?? .system

        let storedTitleSize = userDefaults.double(forKey: Keys.titleFontSize)
        titleFontSize = storedTitleSize == 0 ? 34 : storedTitleSize.clamped(to: Self.titleFontSizeRange)

        let storedContentSize = userDefaults.double(forKey: Keys.contentFontSize)
        contentFontSize = storedContentSize == 0 ? 17 : storedContentSize.clamped(to: Self.contentFontSizeRange)

        let storedBrowser = userDefaults.string(forKey: Keys.browserOption)
        browserOption = Self.resolvedBrowserOption(
            BrowserOption(rawValue: storedBrowser ?? "") ?? .systemDefault
        )

        customBrowserPath = userDefaults.string(forKey: Keys.customBrowserPath) ?? ""
    }

    func ensureValidSelections() {
        let resolvedBrowser = Self.resolvedBrowserOption(browserOption)
        if resolvedBrowser != browserOption {
            browserOption = resolvedBrowser
        }
    }

    private static func resolvedBrowserOption(_ option: BrowserOption) -> BrowserOption {
        BrowserOption.selectableOptions.contains(option) ? option : .systemDefault
    }

    func resetToDefaults() {
        accentColor = .blue
        appearanceMode = .system
        titleFontSize = 34
        contentFontSize = 17
        browserOption = .systemDefault
        customBrowserPath = ""
    }

    private enum Keys {
        static let accentColor = "accentColor"
        static let appearanceMode = "appearanceMode"
        static let titleFontSize = "titleFontSize"
        static let contentFontSize = "contentFontSize"
        static let browserOption = "browserOption"
        static let customBrowserPath = "customBrowserPath"
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(accentColor.rawValue, forKey: Keys.accentColor)
        defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
        defaults.set(titleFontSize, forKey: Keys.titleFontSize)
        defaults.set(contentFontSize, forKey: Keys.contentFontSize)
        defaults.set(browserOption.rawValue, forKey: Keys.browserOption)
        defaults.set(customBrowserPath, forKey: Keys.customBrowserPath)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
