import Testing
import Foundation
@testable import Rumo

/// Tests for CryptoService
struct CryptoTests {

    // MARK: - Encryption Tests

    @Test("Encrypt and decrypt string")
    func testEncryptDecryptString() async throws {
        let crypto = CryptoService.shared
        let plaintext = "This is a secret journal entry about my day."

        let encrypted = try await crypto.encrypt(plaintext)
        let decrypted = try await crypto.decrypt(encrypted)

        #expect(decrypted == plaintext)
        #expect(encrypted != Data(plaintext.utf8))
    }

    @Test("Encrypt and decrypt data")
    func testEncryptDecryptData() async throws {
        let crypto = CryptoService.shared
        let originalData = Data("Binary data content".utf8)

        let encrypted = try await crypto.encrypt(originalData)
        let decrypted = try await crypto.decryptToData(encrypted)

        #expect(decrypted == originalData)
    }

    @Test("Encrypted data is different each time due to random nonce")
    func testRandomNonce() async throws {
        let crypto = CryptoService.shared
        let plaintext = "Same text"

        let encrypted1 = try await crypto.encrypt(plaintext)
        let encrypted2 = try await crypto.encrypt(plaintext)

        // Same plaintext should produce different ciphertext due to random nonce
        #expect(encrypted1 != encrypted2)

        // But both should decrypt to the same value
        let decrypted1 = try await crypto.decrypt(encrypted1)
        let decrypted2 = try await crypto.decrypt(encrypted2)
        #expect(decrypted1 == decrypted2)
    }

    @Test("Empty string encryption")
    func testEmptyString() async throws {
        let crypto = CryptoService.shared
        let plaintext = ""

        let encrypted = try await crypto.encrypt(plaintext)
        let decrypted = try await crypto.decrypt(encrypted)

        #expect(decrypted == plaintext)
    }

    @Test("Unicode string encryption")
    func testUnicodeString() async throws {
        let crypto = CryptoService.shared
        let plaintext = "日本語テスト 🎉 Émojis são úteis! 中文"

        let encrypted = try await crypto.encrypt(plaintext)
        let decrypted = try await crypto.decrypt(encrypted)

        #expect(decrypted == plaintext)
    }

    @Test("Long text encryption")
    func testLongText() async throws {
        let crypto = CryptoService.shared
        let plaintext = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)

        let encrypted = try await crypto.encrypt(plaintext)
        let decrypted = try await crypto.decrypt(encrypted)

        #expect(decrypted == plaintext)
    }

    // MARK: - Hashing Tests

    @Test("Hash produces consistent results")
    func testHashConsistency() async {
        let crypto = CryptoService.shared
        let text = "Hash this text"

        let hash1 = await crypto.hash(text)
        let hash2 = await crypto.hash(text)

        #expect(hash1 == hash2)
    }

    @Test("Different inputs produce different hashes")
    func testHashDifference() async {
        let crypto = CryptoService.shared

        let hash1 = await crypto.hash("Text A")
        let hash2 = await crypto.hash("Text B")

        #expect(hash1 != hash2)
    }

    @Test("Hash is hex-encoded SHA-256")
    func testHashFormat() async {
        let crypto = CryptoService.shared
        let hash = await crypto.hash("Test")

        // SHA-256 produces 64 hex characters
        #expect(hash.count == 64)

        // Should only contain hex characters
        let hexCharacters = CharacterSet(charactersIn: "0123456789abcdef")
        #expect(hash.unicodeScalars.allSatisfy { hexCharacters.contains($0) })
    }

    // MARK: - Key Management Tests

    @Test("Key exists after encryption")
    func testKeyCreation() async throws {
        let crypto = CryptoService.shared

        // Encrypt something to ensure key exists
        _ = try await crypto.encrypt("test")

        #expect(await crypto.hasEncryptionKey() == true)
    }
}

// MARK: - Conflict Resolution Tests

struct ConflictResolverTests {

    @Test("Last write wins resolution")
    func testLastWriteWins() {
        // This test would need mock Syncable types
        // Placeholder for the pattern
    }

    @Test("Local delete vs remote update")
    func testDeleteVsUpdate() {
        // Placeholder for delete vs update conflict resolution
    }
}
