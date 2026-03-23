import SwiftData
import Foundation

// MARK: - Smart List Filter

struct SmartListFilter: Codable, Sendable, Equatable {
    enum FilterType: String, Codable, Sendable {
        case today
        case upcoming
        case overdue
        case highPriority
        case noDate
        case completed
        case custom
    }

    var type: FilterType
    var customPredicate: String? // For custom filters

    init(type: FilterType, customPredicate: String? = nil) {
        self.type = type
        self.customPredicate = customPredicate
    }
}

// MARK: - Task List Model

@Model
final class TaskList: Sendable {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var icon: String
    var sortOrder: Int
    var isSmartList: Bool
    var smartListFilter: SmartListFilter?
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    // Relationship to tasks
    @Relationship(deleteRule: .cascade)
    var tasks: [TaskItem]?

    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#007AFF",
        icon: String = "list.bullet",
        sortOrder: Int = 0,
        isSmartList: Bool = false,
        smartListFilter: SmartListFilter? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.sortOrder = sortOrder
        self.isSmartList = isSmartList
        self.smartListFilter = smartListFilter
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
        self.tasks = nil
    }
}

// MARK: - Syncable Conformance

extension TaskList: Syncable {
    static var tableName: String { "task_lists" }
}

// MARK: - Default Lists

extension TaskList {

    static func createDefaultLists() -> [TaskList] {
        [
            TaskList(
                name: String(localized: "list.inbox"),
                color: "#007AFF",
                icon: "tray.fill",
                sortOrder: 0
            ),
            TaskList(
                name: String(localized: "list.today"),
                color: "#FF9500",
                icon: "star.fill",
                sortOrder: 1,
                isSmartList: true,
                smartListFilter: SmartListFilter(type: .today)
            ),
            TaskList(
                name: String(localized: "list.upcoming"),
                color: "#34C759",
                icon: "calendar",
                sortOrder: 2,
                isSmartList: true,
                smartListFilter: SmartListFilter(type: .upcoming)
            ),
        ]
    }
}
