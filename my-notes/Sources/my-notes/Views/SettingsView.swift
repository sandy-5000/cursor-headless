import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Picker("Appearance", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            } header: {
                Text("Appearance")
            } footer: {
                Text("Choose light, dark, or match your Mac system setting.")
            }

            Section {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                    spacing: 16
                ) {
                    ForEach(AccentColorOption.allCases) { option in
                        AccentColorButton(
                            option: option,
                            isSelected: settings.accentColor == option
                        ) {
                            settings.accentColor = option
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            } header: {
                Text("Base Color")
            } footer: {
                Text("Used for highlights, buttons, and selected notes.")
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text("\(Int(settings.titleFontSize)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: $settings.titleFontSize,
                        in: AppSettings.titleFontSizeRange,
                        step: 1
                    )

                    Text("Sample Title")
                        .font(settings.titleFont())
                        .foregroundStyle(settings.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
            } header: {
                Text("Title Font Size")
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Content")
                        Spacer()
                        Text("\(Int(settings.contentFontSize)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: $settings.contentFontSize,
                        in: AppSettings.contentFontSizeRange,
                        step: 1
                    )

                    Text("The quick brown fox jumps over the lazy dog.")
                        .font(settings.bodyFont())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
            } header: {
                Text("Content Font Size")
            }

            Section {
                Button("Reset to Defaults") {
                    settings.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 440)
        .preferredColorScheme(settings.preferredColorScheme)
    }
}

private struct AccentColorButton: View {
    let option: AccentColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? option.color : Color.primary.opacity(0.12),
                            lineWidth: isSelected ? 2 : 1
                        )
                        .frame(width: 40, height: 40)

                    Circle()
                        .fill(option.color)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if isSelected {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2)
                            }
                        }
                }
                .padding(4)

                Text(option.label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? option.color.opacity(0.12) : Color.clear)
            }
        }
        .buttonStyle(.plain)
    }
}
