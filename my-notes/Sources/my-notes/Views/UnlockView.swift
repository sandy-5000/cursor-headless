import SwiftUI

struct UnlockView: View {
    @Environment(AppSettings.self) private var settings
    @Bindable var vault: VaultManager
    let store: NotesStore
    @Binding var unlockError: String?

    @State private var password = ""
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(settings.accent.opacity(0.1))
                    .frame(width: 96, height: 96)
                Image(systemName: "lock.shield.fill")
                    .font(settings.font(size: settings.contentFontSize + 12, weight: .medium))
                    .foregroundStyle(settings.accent)
            }

            VStack(spacing: 8) {
                Text("My Notes is Locked")
                    .font(settings.titleFont())
                Text("Enter your encryption password to view your notes.")
                    .font(settings.bodyFont())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                SecureField("Password", text: $password)
                    .font(settings.bodyFont())
                    .textFieldStyle(.roundedBorder)
                    .focused($isPasswordFocused)
                    .onSubmit(unlock)

                if let unlockError {
                    Text(unlockError)
                        .font(settings.captionFont())
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: 320)

            Button(action: unlock) {
                Text("Unlock")
                    .font(settings.font(size: settings.contentFontSize - 3, weight: .semibold))
                    .frame(maxWidth: 320)
            }
            .buttonStyle(.borderedProminent)
            .tint(settings.accent)
            .disabled(password.isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onAppear {
            isPasswordFocused = true
        }
    }

    private func unlock() {
        unlockError = nil
        do {
            try vault.unlock(password: password)
            password = ""
            store.prepareForUse()
        } catch {
            unlockError = error.localizedDescription
        }
    }
}
