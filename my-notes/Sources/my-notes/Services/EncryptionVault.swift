import CryptoKit
import Foundation

enum VaultError: LocalizedError {
    case encryptionFailed
    case invalidPassword
    case vaultNotConfigured
    case vaultAlreadyEnabled
    case vaultNotEnabled

    var errorDescription: String? {
        switch self {
        case .encryptionFailed: "Could not encrypt or decrypt note data."
        case .invalidPassword: "Incorrect password."
        case .vaultNotConfigured: "Encryption is not configured."
        case .vaultAlreadyEnabled: "Encryption is already enabled."
        case .vaultNotEnabled: "Encryption is not enabled."
        }
    }
}

enum EncryptionVault {
    static let pbkdfIterations = 120_000

    static func generateSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    static func generateDataKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    static func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        var material = Data(password.utf8)
        material.append(salt)
        material.append(Data("MyNotes.PBKDF.v1".utf8))
        for _ in 0..<pbkdfIterations {
            material = Data(SHA256.hash(data: material))
        }
        return SymmetricKey(data: material)
    }

    static func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else { throw VaultError.encryptionFailed }
        return combined
    }

    static func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
    }

    static func wrapKey(_ dataKey: SymmetricKey, password: String, salt: Data) throws -> Data {
        let kek = deriveKey(from: password, salt: salt)
        let keyData = dataKey.withUnsafeBytes { Data($0) }
        return try encrypt(keyData, using: kek)
    }

    static func unwrapKey(_ wrapped: Data, password: String, salt: Data) throws -> SymmetricKey {
        let kek = deriveKey(from: password, salt: salt)
        let keyData = try decrypt(wrapped, using: kek)
        return SymmetricKey(data: keyData)
    }
}

struct VaultMetadata: Codable {
    let version: Int
    let salt: Data
    let wrappedKey: Data
}
