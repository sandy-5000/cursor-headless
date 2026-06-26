import SwiftUI

struct NoteRowView: View {
    @Environment(AppSettings.self) private var settings
    let note: Note
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(isSelected ? settings.accent : Color.primary.opacity(0.12))
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(note.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.92))
                    .lineLimit(1)

                Text(note.preview)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                NoteDateStampView(note: note, compact: true)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? settings.accentSoft : Color.clear)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(settings.accent.opacity(0.25), lineWidth: 1)
                    }
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isSelected)
    }
}
