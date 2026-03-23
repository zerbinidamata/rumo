import Foundation
import CryptoKit

/// Service for encrypting and decrypting sensitive data.
/// Uses AES-256-GCM for journal entries as specified in PRD.
actor CryptoService {

    // MARK: - Singleton

    static let shared = CryptoService()

    // MARK: - Dependencies

    private let keychain: KeychainManager

    // MARK: - Initialization

    private init(keychain: KeychainManager = .shared) {
        self.keychain = keychain
    }

    // MARK: - Encryption

    /// Encrypts a string using AES-256-GCM
    /// - Parameter plaintext: The string to encrypt
    /// - Returns: Encrypted data (nonce + ciphertext + tag)
    func encrypt(_ plaintext: String) throws -> Data {
        guard let data = plaintext.data(using: .utf8) else {
            throw CryptoError.encodingFailed
        }
        return try encrypt(data)
    }

    /// Encrypts data using AES-256-GCM
    /// - Parameter data: The data to encrypt
    /// - Returns: Encrypted data (nonce + ciphertext + tag)
    func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()

        // Generate a random nonce
        let nonce = AES.GCM.Nonce()

        // Encrypt the data
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)

        // Combine nonce + ciphertext + tag
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }

        return combined
    }

    // MARK: - Decryption

    /// Decrypts data and returns the original string
    /// - Parameter ciphertext: The encrypted data
    /// - Returns: The decrypted string
    func decrypt(_ ciphertext: Data) throws -> String {
        let data = try decryptToData(ciphertext)

        guard let string = String(data: data, encoding: .utf8) else {
            throw CryptoError.decodingFailed
        }

        return string
    }

    /// Decrypts data and returns the original data
    /// - Parameter ciphertext: The encrypted data (nonce + ciphertext + tag)
    /// - Returns: The decrypted data
    func decryptToData(_ ciphertext: Data) throws -> Data {
        let key = try getOrCreateKey()

        // Parse the sealed box from combined data
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)

        // Decrypt the data
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        return decryptedData
    }

    // MARK: - Hashing

    /// Creates a SHA-256 hash of the given string
    /// - Parameter string: The string to hash
    /// - Returns: Hex-encoded hash string
    func hash(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else {
            return ""
        }
        return hash(data)
    }

    /// Creates a SHA-256 hash of the given data
    /// - Parameter data: The data to hash
    /// - Returns: Hex-encoded hash string
    func hash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Key Management

    /// Gets the existing encryption key or creates a new one
    private func getOrCreateKey() throws -> SymmetricKey {
        // Try to get existing key from keychain
        if let keyData = try keychain.getSymmetricKey(
            for: KeychainManager.journalEncryptionKeyIdentifier
        ) {
            return SymmetricKey(data: keyData)
        }

        // Generate new 256-bit key
        let key = SymmetricKey(size: .bits256)

        // Store in keychain
        let keyData = key.withUnsafeBytes { Data($0) }
        try keychain.setSymmetricKey(
            keyData,
            for: KeychainManager.journalEncryptionKeyIdentifier
        )

        return key
    }

    /// Checks if an encryption key exists
    func hasEncryptionKey() -> Bool {
        do {
            return try keychain.getSymmetricKey(
                for: KeychainManager.journalEncryptionKeyIdentifier
            ) != nil
        } catch {
            return false
        }
    }

    /// Exports the encryption key (for backup purposes)
    /// WARNING: This is sensitive data - handle with extreme care
    func exportKey() throws -> Data {
        guard let keyData = try keychain.getSymmetricKey(
            for: KeychainManager.journalEncryptionKeyIdentifier
        ) else {
            throw CryptoError.keyNotFound
        }
        return keyData
    }

    /// Imports an encryption key (for restore purposes)
    /// WARNING: This will overwrite any existing key
    func importKey(_ keyData: Data) throws {
        guard keyData.count == 32 else { // 256 bits = 32 bytes
            throw CryptoError.invalidKeySize
        }
        try keychain.setSymmetricKey(
            keyData,
            for: KeychainManager.journalEncryptionKeyIdentifier
        )
    }

    /// Deletes the encryption key
    /// WARNING: This will make all encrypted journal entries unreadable
    func deleteKey() throws {
        try keychain.deleteSymmetricKey(
            for: KeychainManager.journalEncryptionKeyIdentifier
        )
    }
}

// MARK: - Crypto Error

enum CryptoError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case encryptionFailed
    case decryptionFailed
    case keyNotFound
    case invalidKeySize

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return String(localized: "error.crypto.encoding")
        case .decodingFailed:
            return String(localized: "error.crypto.decoding")
        case .encryptionFailed:
            return String(localized: "error.crypto.encryption")
        case .decryptionFailed:
            return String(localized: "error.crypto.decryption")
        case .keyNotFound:
            return String(localized: "error.crypto.keyNotFound")
        case .invalidKeySize:
            return String(localized: "error.crypto.invalidKeySize")
        }
    }
}

// MARK: - Journal Entry Extension

extension JournalEntry {

    /// Decrypts and returns the journal body text
    func decryptedBody(using crypto: CryptoService = .shared) async throws -> String {
        try await crypto.decrypt(bodyEncrypted)
    }

    /// Creates an encrypted journal entry from plaintext
    static func create(
        date: Date,
        body: String,
        mood: MoodLevel? = nil,
        crypto: CryptoService = .shared
    ) async throws -> JournalEntry {
        let encrypted = try await crypto.encrypt(body)
        let hash = await crypto.hash(body)

        return JournalEntry(
            date: date,
            bodyEncrypted: encrypted,
            bodyHash: hash,
            mood: mood,
            wordCount: body.split(separator: " ").count
        )
    }

    /// Updates the journal entry with new body text
    func updateBody(
        _ newBody: String,
        crypto: CryptoService = .shared
    ) async throws {
        // Note: In actual implementation, this would need to be done
        // on a mutable copy since JournalEntry is a SwiftData model
        // This is a helper method showing the encryption flow
    }
}
