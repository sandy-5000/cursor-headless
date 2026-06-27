import CryptoKit
import Foundation
import Observation

@MainActor
@Observable
final class VaultManager {
    private(set) var isEncryptionEnabled = false
    private(set) var isUnlocked = false

    private var dataKey: SymmetricKey?
    private var metadata: VaultMetadata?

    let storageURL: URL
    private var vaultMetaURL: URL { storageURL.appendingPathComponent("vault.json") }

    var requiresUnlock: Bool { isEncryptionEnabled && !isUnlocked }

    var canReadNotes: Bool { !isEncryptionEnabled || isUnlocked }

    init(storageDirectory: URL? = nil) {
        storageURL = storageDirectory ?? NotesStore.defaultStorageDirectory()
    }

    func configureOnLaunch() {
        isEncryptionEnabled = FileManager.default.fileExists(atPath: vaultMetaURL.path)
        if isEncryptionEnabled {
            metadata = loadMetadata()
            isUnlocked = false
            dataKey = nil
        } else {
            isUnlocked = true
        }
    }

    func lock() {
        guard isEncryptionEnabled else { return }
        dataKey = nil
        isUnlocked = false
    }

    func unlock(password: String) throws {
        guard isEncryptionEnabled, let metadata else { throw VaultError.vaultNotConfigured }
        do {
            dataKey = try EncryptionVault.unwrapKey(metadata.wrappedKey, password: password, salt: metadata.salt)
            isUnlocked = true
        } catch {
            throw VaultError.invalidPassword
        }
    }

    func enableEncryption(password: String) throws {
        guard !isEncryptionEnabled else { throw VaultError.vaultAlreadyEnabled }
        guard password.count >= 8 else {
            throw NSError(domain: "MyNotes", code: 1, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters."])
        }

        let salt = EncryptionVault.generateSalt()
        let dataKey = EncryptionVault.generateDataKey()
        let wrappedKey = try EncryptionVault.wrapKey(dataKey, password: password, salt: salt)

        let meta = VaultMetadata(version: 1, salt: salt, wrappedKey: wrappedKey)
        try persistMetadata(meta)

        self.metadata = meta
        self.dataKey = dataKey
        self.isEncryptionEnabled = true
        self.isUnlocked = true
    }

    func disableEncryption(password: String) throws {
        guard isEncryptionEnabled, let metadata else { throw VaultError.vaultNotEnabled }
        _ = try verifyPassword(password, metadata: metadata)

        try FileManager.default.removeItem(at: vaultMetaURL)

        self.metadata = nil
        self.dataKey = nil
        self.isEncryptionEnabled = false
        self.isUnlocked = true
    }

    func changePassword(from currentPassword: String, to newPassword: String) throws {
        guard isEncryptionEnabled, let metadata else { throw VaultError.vaultNotEnabled }
        guard newPassword.count >= 8 else {
            throw NSError(domain: "MyNotes", code: 1, userInfo: [NSLocalizedDescriptionKey: "New password must be at least 8 characters."])
        }

        let key = try verifyPassword(currentPassword, metadata: metadata)
        let wrappedKey = try EncryptionVault.wrapKey(key, password: newPassword, salt: metadata.salt)
        let updated = VaultMetadata(version: metadata.version, salt: metadata.salt, wrappedKey: wrappedKey)

        try persistMetadata(updated)
        self.metadata = updated
        self.dataKey = key
        self.isUnlocked = true
    }

    func protect(_ data: Data) throws -> Data {
        guard let dataKey else {
            if isEncryptionEnabled { throw VaultError.vaultNotConfigured }
            return data
        }
        return try EncryptionVault.encrypt(data, using: dataKey)
    }

    func reveal(_ data: Data) throws -> Data {
        guard isEncryptionEnabled else { return data }
        guard let dataKey else { throw VaultError.vaultNotConfigured }
        return try EncryptionVault.decrypt(data, using: dataKey)
    }

    private func verifyPassword(_ password: String, metadata: VaultMetadata) throws -> SymmetricKey {
        do {
            return try EncryptionVault.unwrapKey(metadata.wrappedKey, password: password, salt: metadata.salt)
        } catch {
            throw VaultError.invalidPassword
        }
    }

    private func loadMetadata() -> VaultMetadata? {
        guard let data = try? Data(contentsOf: vaultMetaURL) else { return nil }
        return try? JSONDecoder().decode(VaultMetadata.self, from: data)
    }

    private func persistMetadata(_ metadata: VaultMetadata) throws {
        try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: vaultMetaURL, options: .atomic)
    }
}
