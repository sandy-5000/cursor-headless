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

    var accent: Color { accentColor.color }

    var accentSoft: Color { accentColor.color.opacity(0.14) }

    var preferredColorScheme: ColorScheme? { appearanceMode.colorScheme }

    func titleFont() -> Font {
        .system(size: titleFontSize, weight: .semibold, design: .serif)
    }

    func bodyFont() -> Font {
        .system(size: contentFontSize, weight: .regular, design: .default)
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
    }

    func resetToDefaults() {
        accentColor = .blue
        appearanceMode = .system
        titleFontSize = 34
        contentFontSize = 17
    }

    private enum Keys {
        static let accentColor = "accentColor"
        static let appearanceMode = "appearanceMode"
        static let titleFontSize = "titleFontSize"
        static let contentFontSize = "contentFontSize"
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(accentColor.rawValue, forKey: Keys.accentColor)
        defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
        defaults.set(titleFontSize, forKey: Keys.titleFontSize)
        defaults.set(contentFontSize, forKey: Keys.contentFontSize)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
