import Foundation

/// Resolves conflicts between local and remote data.
/// Uses last-write-wins strategy based on updatedAt timestamp.
struct ConflictResolver {

    // MARK: - Resolution Strategy

    enum Strategy {
        case lastWriteWins
        case localWins
        case remoteWins
        case merge
    }

    // MARK: - Resolution Result

    enum Resolution<T> {
        case keepLocal(T)
        case useRemote(T)
        case merge(T)
        case delete
    }

    // MARK: - Default Strategy

    static let defaultStrategy: Strategy = .lastWriteWins

    // MARK: - Resolve

    /// Resolves a conflict between local and remote versions
    static func resolve<T: Syncable>(
        local: T,
        remote: T,
        strategy: Strategy = defaultStrategy
    ) -> Resolution<T> {
        // Handle deletion
        if local.isDeleted && remote.isDeleted {
            return .delete
        }

        if local.isDeleted {
            return local.updatedAt > remote.updatedAt
                ? .delete
                : .useRemote(remote)
        }

        if remote.isDeleted {
            return remote.updatedAt > local.updatedAt
                ? .delete
                : .keepLocal(local)
        }

        // Apply strategy
        switch strategy {
        case .lastWriteWins:
            if local.updatedAt >= remote.updatedAt {
                return .keepLocal(local)
            } else {
                return .useRemote(remote)
            }

        case .localWins:
            return .keepLocal(local)

        case .remoteWins:
            return .useRemote(remote)

        case .merge:
            // Merge strategy would need type-specific implementation
            // For now, fall back to last-write-wins
            if local.updatedAt >= remote.updatedAt {
                return .keepLocal(local)
            } else {
                return .useRemote(remote)
            }
        }
    }

    /// Resolves when we only have a remote version (new data from server)
    static func resolveNew<T: Syncable>(
        remote: T,
        existsLocally: Bool
    ) -> Resolution<T> {
        if existsLocally {
            // This shouldn't happen - we should have the local version
            return .useRemote(remote)
        }

        if remote.isDeleted {
            return .delete
        }

        return .useRemote(remote)
    }

    /// Resolves when we only have a local version (offline creation)
    static func resolveLocalOnly<T: Syncable>(
        local: T
    ) -> Resolution<T> {
        if local.isDeleted {
            return .delete
        }
        return .keepLocal(local)
    }
}

// MARK: - Conflict Detection

extension ConflictResolver {

    /// Detects if there's a conflict between local and remote
    static func hasConflict<T: Syncable>(
        local: T,
        remote: T
    ) -> Bool {
        // Conflict exists if both have been modified since last sync
        guard let localSyncedAt = local.syncedAt else {
            // Local has never been synced - could be a conflict if remote exists
            return true
        }

        let localModified = local.updatedAt > localSyncedAt
        let remoteModified = remote.updatedAt > localSyncedAt

        return localModified && remoteModified
    }
}

// MARK: - Batch Resolution

extension ConflictResolver {

    /// Resolves conflicts for a batch of items
    static func resolveBatch<T: Syncable>(
        local: [T],
        remote: [T],
        strategy: Strategy = defaultStrategy
    ) -> (keep: [T], update: [T], delete: [UUID]) {
        var keep: [T] = []
        var update: [T] = []
        var delete: [UUID] = []

        let localById = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        let remoteById = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })

        // Process all IDs
        let allIds = Set(localById.keys).union(Set(remoteById.keys))

        for id in allIds {
            let localItem = localById[id]
            let remoteItem = remoteById[id]

            switch (localItem, remoteItem) {
            case let (.some(l), .some(r)):
                // Both exist - resolve conflict
                let resolution = resolve(local: l, remote: r, strategy: strategy)
                switch resolution {
                case .keepLocal(let item):
                    keep.append(item)
                case .useRemote(let item):
                    update.append(item)
                case .merge(let item):
                    update.append(item)
                case .delete:
                    delete.append(id)
                }

            case let (.some(l), .none):
                // Only local - keep or delete
                if l.isDeleted {
                    delete.append(id)
                } else {
                    keep.append(l)
                }

            case let (.none, .some(r)):
                // Only remote - add or delete
                if r.isDeleted {
                    delete.append(id)
                } else {
                    update.append(r)
                }

            case (.none, .none):
                // Shouldn't happen
                break
            }
        }

        return (keep, update, delete)
    }
}
