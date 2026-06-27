import SwiftUI

struct NoteDateStampView: View {
    @Environment(AppSettings.self) private var settings
    let note: Note
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: compact ? 6 : 8) {
            Image(systemName: "clock")
                .font(settings.font(size: compact ? max(settings.contentFontSize - 3, 11) : max(settings.contentFontSize - 2, 12), weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: compact ? 12 : 14, alignment: .center)

            if compact {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.formattedDate)
                    Text(note.formattedTime)
                }
                .font(settings.sidebarCaptionFont())
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(spacing: 6) {
                    Text(note.formattedDate)
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text(note.formattedTime)
                }
                .font(settings.captionFont())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
