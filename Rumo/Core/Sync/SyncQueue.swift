import Foundation
import SwiftData

/// Manages the queue of pending sync operations.
/// Provides utilities for queuing, dequeuing, and monitoring sync status.
@MainActor
final class SyncQueue: ObservableObject {

    // MARK: - Singleton

    static let shared = SyncQueue()

    // MARK: - Published State

    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var lastError: Error?

    // MARK: - Dependencies

    private let modelContainer: ModelContainer

    // MARK: - Initialization

    private init(modelContainer: ModelContainer = .shared) {
        self.modelContainer = modelContainer
        refreshPendingCount()
    }

    // MARK: - Public Methods

    /// Adds an operation to the sync queue
    func enqueue<T: Syncable>(
        _ entity: T,
        operation: SyncOperationType
    ) {
        let context = ModelContext(modelContainer)

        // Check if there's already a pending operation for this entity
        let existingOp = findExistingOperation(
            entityType: T.tableName,
            entityId: entity.id,
            context: context
        )

        if let existing = existingOp {
            // Merge operations
            mergeOperation(existing: existing, new: operation, context: context)
        } else {
            // Create new operation
            let pendingOp = PendingSyncOperation(
                entityType: T.tableName,
                entityId: entity.id,
                operationType: operation
            )
            context.insert(pendingOp)
        }

        try? context.save()
        refreshPendingCount()
    }

    /// Removes an operation from the queue
    func dequeue(_ operation: PendingSyncOperation) {
        let context = ModelContext(modelContainer)
        context.delete(operation)
        try? context.save()
        refreshPendingCount()
    }

    /// Gets all pending operations
    func getPendingOperations() -> [PendingSyncOperation] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<PendingSyncOperation>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Clears all pending operations (use with caution)
    func clearAll() {
        let context = ModelContext(modelContainer)
        let operations = getPendingOperations()

        for op in operations {
            context.delete(op)
        }

        try? context.save()
        refreshPendingCount()
    }

    /// Updates sync status
    func setSyncing(_ syncing: Bool) {
        isSyncing = syncing
        if !syncing {
            lastSyncDate = Date()
        }
    }

    /// Records a sync error
    func recordError(_ error: Error) {
        lastError = error
    }

    /// Clears the last error
    func clearError() {
        lastError = nil
    }

    // MARK: - Private Methods

    private func refreshPendingCount() {
        pendingCount = getPendingOperations().count
    }

    private func findExistingOperation(
        entityType: String,
        entityId: UUID,
        context: ModelContext
    ) -> PendingSyncOperation? {
        let descriptor = FetchDescriptor<PendingSyncOperation>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.first { $0.entityType == entityType && $0.entityId == entityId }
    }

    private func mergeOperation(
        existing: PendingSyncOperation,
        new: SyncOperationType,
        context: ModelContext
    ) {
        // Merge logic:
        // create + update = create
        // create + delete = remove from queue (never synced)
        // update + update = update
        // update + delete = delete
        // delete + any = delete

        switch (existing.operationType, new) {
        case (.create, .delete):
            // Entity was created and deleted before sync - remove from queue
            context.delete(existing)

        case (.create, .update):
            // Still a create, just with newer data
            break

        case (.update, .delete):
            // Change to delete
            existing.operationType = .delete

        case (.delete, _):
            // Already deleted, ignore new operation
            break

        default:
            // Keep existing operation type
            break
        }
    }
}

// MARK: - Sync Status

struct SyncStatus {
    let pendingCount: Int
    let isSyncing: Bool
    let lastSyncDate: Date?
    let lastError: Error?

    var displayStatus: String {
        if isSyncing {
            return String(localized: "sync.status.syncing")
        } else if pendingCount > 0 {
            return String(localized: "sync.status.pending \(pendingCount)")
        } else if let lastSync = lastSyncDate {
            return String(localized: "sync.status.lastSync \(lastSync.relativeString())")
        } else {
            return String(localized: "sync.status.notSynced")
        }
    }

    var icon: String {
        if isSyncing {
            return "arrow.triangle.2.circlepath"
        } else if pendingCount > 0 {
            return "exclamationmark.icloud"
        } else if lastError != nil {
            return "exclamationmark.triangle"
        } else {
            return "checkmark.icloud"
        }
    }
}

extension SyncQueue {

    var status: SyncStatus {
        SyncStatus(
            pendingCount: pendingCount,
            isSyncing: isSyncing,
            lastSyncDate: lastSyncDate,
            lastError: lastError
        )
    }
}
