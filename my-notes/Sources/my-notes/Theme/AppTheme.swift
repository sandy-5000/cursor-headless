import AppKit
import SwiftUI

enum AppTheme {
    static let sidebarGradient = LinearGradient(
        colors: [
            Color(nsColor: .controlBackgroundColor).opacity(0.95),
            Color(nsColor: .windowBackgroundColor).opacity(0.88),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let editorGradient = LinearGradient(
        colors: [
            Color(nsColor: .textBackgroundColor),
            Color(nsColor: .windowBackgroundColor).opacity(0.55),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardShadow = Color.black.opacity(0.08)
    static let subtleBorder = Color.primary.opacity(0.06)

    static func captionFont(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

struct GlassBackground: View {
    var cornerRadius: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.subtleBorder, lineWidth: 1)
            }
    }
}

struct PinnedSectionHeaderBackground: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.regularMaterial)

            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor).opacity(0.35),
                    Color(nsColor: .controlBackgroundColor).opacity(0.12),
                    .clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 18)
            .offset(y: 18)
            .allowsHitTesting(false)
        }
    }
}

struct AccentDot: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Circle()
            .fill(settings.accent)
            .frame(width: 8, height: 8)
            .shadow(color: settings.accent.opacity(0.25), radius: 3)
    }
}
