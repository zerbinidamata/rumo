import SwiftData
import Foundation

// MARK: - Sync Operation Type

enum SyncOperationType: String, Codable, Sendable {
    case create
    case update
    case delete
}

// MARK: - Pending Sync Operation Model

/// Represents a local change that needs to be synced to Supabase.
/// Used for offline queue management.
@Model
final class PendingSyncOperation: Sendable {
    @Attribute(.unique) var id: UUID
    var entityType: String
    var entityId: UUID
    var operationType: SyncOperationType
    var payload: Data? // JSON encoded entity data for create/update
    var retryCount: Int
    var lastError: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        entityType: String,
        entityId: UUID,
        operationType: SyncOperationType,
        payload: Data? = nil
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.operationType = operationType
        self.payload = payload
        self.retryCount = 0
        self.lastError = nil
        self.createdAt = Date()
    }
}

// MARK: - Convenience Methods

extension PendingSyncOperation {

    /// Maximum retry attempts before giving up
    static let maxRetries = 5

    /// Whether this operation should be retried
    var shouldRetry: Bool {
        retryCount < Self.maxRetries
    }

    /// Increments retry count and records error
    func recordFailure(error: String) {
        retryCount += 1
        lastError = error
    }

    /// Creates a sync operation for any Syncable entity
    static func create<T: Syncable>(
        for entity: T,
        operation: SyncOperationType,
        encoder: JSONEncoder = JSONEncoder()
    ) -> PendingSyncOperation? {
        var payload: Data?

        if operation != .delete {
            // Encode the entity for create/update operations
            // Note: The actual encoding depends on the entity's Codable conformance
            // This is a placeholder - actual implementation in Phase 3
            payload = nil
        }

        return PendingSyncOperation(
            entityType: T.tableName,
            entityId: entity.id,
            operationType: operation,
            payload: payload
        )
    }
}
