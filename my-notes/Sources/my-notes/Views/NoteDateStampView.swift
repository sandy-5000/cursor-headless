import SwiftUI

struct NoteDateStampView: View {
    let note: Note
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: compact ? 6 : 8) {
            Image(systemName: "clock")
                .font(.system(size: compact ? 10 : 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: compact ? 12 : 14, alignment: .center)

            if compact {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.formattedDate)
                    Text(note.formattedTime)
                }
                .font(AppTheme.captionFont(size: 11))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(spacing: 6) {
                    Text(note.formattedDate)
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text(note.formattedTime)
                }
                .font(AppTheme.captionFont(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
