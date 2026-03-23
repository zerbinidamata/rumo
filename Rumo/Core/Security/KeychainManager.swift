import Foundation
import Security

/// Secure storage manager using iOS Keychain.
/// All sensitive data (tokens, encryption keys) should be stored here.
final class KeychainManager: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = KeychainManager()

    // MARK: - Configuration

    private let service: String
    private let accessGroup: String?

    // MARK: - Initialization

    private init(
        service: String = Config.bundleIdentifier,
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - String Operations

    /// Stores a string value in the keychain
    func set(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try set(data, for: key)
    }

    /// Retrieves a string value from the keychain
    func getString(for key: String) throws -> String? {
        guard let data = try getData(for: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        return string
    }

    // MARK: - Data Operations

    /// Stores data in the keychain
    func set(_ data: Data, for key: String) throws {
        // Delete existing item first
        try? delete(for: key)

        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Retrieves data from the keychain
    func getData(for key: String) throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Deletes an item from the keychain
    func delete(for key: String) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Checks if a key exists in the keychain
    func exists(key: String) -> Bool {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = false

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Deletes all items for this service
    func deleteAll() throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Symmetric Key Operations

    /// Stores a symmetric key in the keychain
    func setSymmetricKey(_ key: Data, for identifier: String) throws {
        // Delete existing key first
        try? deleteSymmetricKey(for: identifier)

        // Use generic password storage for cross-platform compatibility
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "key_\(identifier)",
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Retrieves a symmetric key from the keychain
    func getSymmetricKey(for identifier: String) throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "key_\(identifier)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Deletes a symmetric key from the keychain
    func deleteSymmetricKey(for identifier: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "key_\(identifier)"
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Private Methods

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - Keychain Error

enum KeychainError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case unhandledError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for keychain storage"
        case .decodingFailed:
            return "Failed to decode data from keychain"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - Keychain Keys

extension KeychainManager {

    /// Key for journal encryption key
    static let journalEncryptionKeyIdentifier = "com.rumo.journal.encryptionKey"

    /// Key for user ID
    static let userIdKey = "com.rumo.userId"

    /// Key for device ID (for sync)
    static let deviceIdKey = "com.rumo.deviceId"
}
