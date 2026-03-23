import Foundation
import SwiftData
import Combine
import Supabase

/// Central manager for local-first synchronization with Supabase.
///
/// Design principles:
/// - All writes go to SwiftData first (instant UI response)
/// - Changes are queued and synced in background
/// - Conflicts resolved by last-write-wins (updatedAt)
/// - Works fully offline with automatic retry on reconnect
actor SyncManager {

    // MARK: - Singleton

    static let shared = SyncManager()

    // MARK: - Dependencies

    private let supabase: SupabaseManager
    private let networkMonitor: NetworkMonitor
    private let modelContainer: ModelContainer

    // MARK: - State

    private var isSyncing: Bool = false
    private var syncTask: Task<Void, Never>?

    // MARK: - Configuration

    private let batchSize = 50
    private let retryDelay: TimeInterval = 5
    private let maxRetries = 5

    // MARK: - Initialization

    private init() {
        self.supabase = SupabaseManager.shared
        self.networkMonitor = NetworkMonitor.shared
        self.modelContainer = ModelContainer.shared
    }

    // MARK: - Public Methods

    /// Starts the sync service
    func start() async {
        // Sync functionality will be implemented when backend is ready
        print("SyncManager: start() called - sync not yet implemented")
    }

    /// Stops the sync service
    func stop() async {
        syncTask?.cancel()
        syncTask = nil
    }

    /// Performs a full bidirectional sync
    func performFullSync() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        // Sync functionality will be implemented when backend is ready
        print("SyncManager: performFullSync() called - sync not yet implemented")
    }

    /// Enqueues a local change for sync
    func enqueue<T: Syncable>(
        _ entity: T,
        operation: SyncOperationType
    ) async {
        let context = ModelContext(modelContainer)

        let pendingOp = PendingSyncOperation(
            entityType: T.tableName,
            entityId: entity.id,
            operationType: operation
        )

        context.insert(pendingOp)
        try? context.save()
    }
}
