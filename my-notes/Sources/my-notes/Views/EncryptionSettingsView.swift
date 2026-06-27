import SwiftUI

struct EncryptionSettingsView: View {
    @Bindable var container: AppContainer
    @Bindable var settings: AppSettings

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private var vault: VaultManager { container.vault }
    private var store: NotesStore { container.store }

    var body: some View {
        Form {
            appearanceSections
            encryptionSection
            linksSection
            resetSection
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 440)
        .preferredColorScheme(settings.preferredColorScheme)
        .onAppear {
            if !vault.requiresUnlock {
                store.prepareForUse()
            }
        }
    }

    @ViewBuilder
    private var appearanceSections: some View {
        Section {
            Picker("Appearance", selection: $settings.appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
        } header: {
            Text("Appearance")
        }

        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(AccentColorOption.allCases) { option in
                    AccentColorButton(option: option, isSelected: settings.accentColor == option) {
                        settings.accentColor = option
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        } header: {
            Text("Base Color")
        }

        fontSection(title: "Title Font Size", size: $settings.titleFontSize, range: AppSettings.titleFontSizeRange) {
            Text("Sample Title").font(settings.titleFont()).foregroundStyle(settings.accent)
        }

        fontSection(title: "Content Font Size", size: $settings.contentFontSize, range: AppSettings.contentFontSizeRange) {
            Text("The quick brown fox jumps over the lazy dog.").font(settings.bodyFont())
        }
    }

    @ViewBuilder
    private var encryptionSection: some View {
        Section {
            HStack {
                Label(vault.isEncryptionEnabled ? "Enabled" : "Off", systemImage: vault.isEncryptionEnabled ? "lock.fill" : "lock.open")
                Spacer()
                if vault.isEncryptionEnabled {
                    Text("AES-256 encrypted")
                        .font(settings.captionFont())
                        .foregroundStyle(.secondary)
                }
            }

            if vault.isEncryptionEnabled && vault.requiresUnlock {
                Text("Unlock My Notes first to change encryption settings.")
                    .font(settings.captionFont())
                    .foregroundStyle(.secondary)
            } else if vault.isEncryptionEnabled {
                SecureField("Current password", text: $currentPassword)

                SecureField("New password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmNewPassword)

                Button("Change Password") {
                    changePassword()
                }
                .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty)

                SecureField("Password to disable encryption", text: $password)

                Button("Disable Encryption", role: .destructive) {
                    disableEncryption()
                }
                .disabled(password.isEmpty)
            } else {
                SecureField("Create password", text: $password)
                SecureField("Confirm password", text: $confirmPassword)

                Button("Enable Encryption") {
                    enableEncryption()
                }
                .disabled(password.isEmpty || confirmPassword.isEmpty)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(settings.captionFont())
                    .foregroundStyle(.green)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(settings.captionFont())
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Encryption")
        } footer: {
            Text("Notes are encrypted on disk with AES-256. Other apps only see unreadable data. You need your password each time you open My Notes.")
        }
    }

    @ViewBuilder
    private var linksSection: some View {
        Section {
            Picker("Open links with", selection: $settings.browserOption) {
                ForEach(BrowserOption.selectableOptions) { browser in
                    Text(browser.label).tag(browser)
                }
            }
        } header: {
            Text("Links")
        }
    }

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button("Reset to Defaults") {
                settings.resetToDefaults()
            }
        }
    }

    @ViewBuilder
    private func fontSection(title: String, size: Binding<Double>, range: ClosedRange<Double>, @ViewBuilder sample: () -> some View) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Size")
                    Spacer()
                    Text("\(Int(size.wrappedValue)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: size, in: range, step: 1)
                sample()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
        } header: {
            Text(title)
        }
    }

    private func enableEncryption() {
        clearMessages()
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        do {
            if vault.requiresUnlock {
                try vault.unlock(password: password)
                store.prepareForUse()
            } else if store.notes.isEmpty {
                store.prepareForUse()
            }

            try vault.enableEncryption(password: password)
            store.enableEncryption(with: vault)
            statusMessage = "Encryption enabled. Your notes are now protected."
            clearPasswordFields()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func disableEncryption() {
        clearMessages()
        do {
            if vault.requiresUnlock {
                try vault.unlock(password: password)
                store.prepareForUse()
            }
            try vault.disableEncryption(password: password)
            store.disableEncryption(with: vault)
            statusMessage = "Encryption disabled. Notes are stored as plain text again."
            clearPasswordFields()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func changePassword() {
        clearMessages()
        guard newPassword == confirmNewPassword else {
            errorMessage = "New passwords do not match."
            return
        }

        do {
            try vault.changePassword(from: currentPassword, to: newPassword)
            statusMessage = "Password updated."
            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearMessages() {
        statusMessage = nil
        errorMessage = nil
    }

    private func clearPasswordFields() {
        password = ""
        confirmPassword = ""
        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
    }
}

private struct AccentColorButton: View {
    @Environment(AppSettings.self) private var settings
    let option: AccentColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? option.color : Color.primary.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                        .frame(width: 40, height: 40)
                    Circle()
                        .fill(option.color)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if isSelected {
                                Circle().strokeBorder(.white, lineWidth: 2)
                            }
                        }
                }
                .padding(4)
                Text(option.label)
                    .font(settings.font(size: max(settings.contentFontSize - 6, 11), weight: isSelected ? .semibold : .regular))
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
