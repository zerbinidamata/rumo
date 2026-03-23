import SwiftData
import Foundation

// MARK: - Task Tag Model

@Model
final class TaskTag: Sendable {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#8E8E93"
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
    }
}

// MARK: - Syncable Conformance

extension TaskTag: Syncable {
    static var tableName: String { "task_tags" }
}
