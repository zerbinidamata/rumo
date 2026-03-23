import Foundation

/// Protocol for models that can be synced with Supabase.
/// Provides common properties needed for local-first sync.
protocol Syncable {
    /// Unique identifier for the entity
    var id: UUID { get }

    /// Timestamp when the entity was created locally
    var createdAt: Date { get }

    /// Timestamp when the entity was last modified locally
    var updatedAt: Date { get set }

    /// Timestamp when the entity was last successfully synced to server
    /// nil means never synced
    var syncedAt: Date? { get set }

    /// Timestamp when the entity was soft-deleted
    /// nil means not deleted
    var deletedAt: Date? { get set }

    /// Name of the Supabase table for this entity
    static var tableName: String { get }
}

extension Syncable {

    /// Whether this entity has local changes that need to be synced
    var needsSync: Bool {
        guard let syncedAt = syncedAt else { return true }
        return updatedAt > syncedAt
    }

    /// Whether this entity has been soft-deleted
    var isDeleted: Bool {
        deletedAt != nil
    }

    /// Marks the entity as synced with the current timestamp
    mutating func markAsSynced() {
        syncedAt = Date()
    }

    /// Marks the entity as deleted with the current timestamp
    mutating func markAsDeleted() {
        deletedAt = Date()
        updatedAt = Date()
    }
}
