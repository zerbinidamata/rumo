import SwiftData
import Foundation
import SwiftUI

// MARK: - Task Priority

enum TaskPriority: Int, Codable, CaseIterable, Sendable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var displayName: String {
        switch self {
        case .none: return String(localized: "priority.none")
        case .low: return String(localized: "priority.low")
        case .medium: return String(localized: "priority.medium")
        case .high: return String(localized: "priority.high")
        }
    }

    var localizedName: LocalizedStringKey {
        switch self {
        case .none: return "priority.none"
        case .low: return "priority.low"
        case .medium: return "priority.medium"
        case .high: return "priority.high"
        }
    }

    var color: String {
        switch self {
        case .none: return "#8E8E93"
        case .low: return "#34C759"
        case .medium: return "#FF9500"
        case .high: return "#FF3B30"
        }
    }
}

// MARK: - Subtask

struct Subtask: Codable, Identifiable, Sendable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
    }
}

// MARK: - Task Item Model

@Model
final class TaskItem: Sendable {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var dueDate: Date?
    var hasTime: Bool
    var priorityValue: Int
    var isCompleted: Bool
    var completedAt: Date?
    var sortOrder: Int

    // Reminders
    var reminderDate: Date?
    var locationReminder: String?

    // Recurrence
    var recurrenceRule: String?

    // Pomodoro
    var pomodoroEstimate: Int
    var pomodoroActual: Int

    // Subtasks (stored as JSON)
    var subtasksData: Data?

    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \TaskList.tasks)
    var list: TaskList?

    @Relationship(deleteRule: .nullify)
    var tags: [TaskTag]?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        hasTime: Bool = false,
        priority: TaskPriority = .none,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        sortOrder: Int = 0,
        reminderDate: Date? = nil,
        locationReminder: String? = nil,
        recurrenceRule: String? = nil,
        pomodoroEstimate: Int = 0,
        pomodoroActual: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasTime = hasTime
        self.priorityValue = priority.rawValue
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.sortOrder = sortOrder
        self.reminderDate = reminderDate
        self.locationReminder = locationReminder
        self.recurrenceRule = recurrenceRule
        self.pomodoroEstimate = pomodoroEstimate
        self.pomodoroActual = pomodoroActual
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
        self.subtasksData = nil
        self.list = nil
        self.tags = nil
    }

    // MARK: - Priority

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityValue) ?? .none }
        set { priorityValue = newValue.rawValue }
    }

    // MARK: - Subtasks

    var subtasks: [Subtask]? {
        get {
            guard let data = subtasksData else { return nil }
            return try? JSONDecoder().decode([Subtask].self, from: data)
        }
        set {
            subtasksData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Computed Properties

    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    var isRecurring: Bool {
        recurrenceRule != nil
    }

    var hasSubtasks: Bool {
        guard let subtasks = subtasks else { return false }
        return !subtasks.isEmpty
    }

    var subtaskProgress: Double {
        guard let subtasks = subtasks, !subtasks.isEmpty else { return 0 }
        let completed = subtasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(subtasks.count)
    }

    // MARK: - Methods

    func markAsModified() {
        updatedAt = Date()
        syncedAt = nil
    }

    func complete() {
        isCompleted = true
        completedAt = Date()
        markAsModified()
    }

    func uncomplete() {
        isCompleted = false
        completedAt = nil
        markAsModified()
    }
}

// MARK: - Syncable Conformance

extension TaskItem: Syncable {
    static var tableName: String { "task_items" }
}

// MARK: - DTO for Supabase

extension TaskItem {
    struct DTO: Codable, Sendable {
        let id: UUID
        let title: String
        let notes: String?
        let dueDate: Date?
        let hasTime: Bool
        let priority: Int
        let isCompleted: Bool
        let completedAt: Date?
        let sortOrder: Int
        let reminderDate: Date?
        let locationReminder: String?
        let recurrenceRule: String?
        let pomodoroEstimate: Int
        let pomodoroActual: Int
        let subtasks: [Subtask]?
        let listId: UUID?
        let tagIds: [UUID]?
        let createdAt: Date
        let updatedAt: Date
        let deletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case notes
            case dueDate = "due_date"
            case hasTime = "has_time"
            case priority
            case isCompleted = "is_completed"
            case completedAt = "completed_at"
            case sortOrder = "sort_order"
            case reminderDate = "reminder_date"
            case locationReminder = "location_reminder"
            case recurrenceRule = "recurrence_rule"
            case pomodoroEstimate = "pomodoro_estimate"
            case pomodoroActual = "pomodoro_actual"
            case subtasks
            case listId = "list_id"
            case tagIds = "tag_ids"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case deletedAt = "deleted_at"
        }
    }

    func toDTO() -> DTO {
        DTO(
            id: id,
            title: title,
            notes: notes,
            dueDate: dueDate,
            hasTime: hasTime,
            priority: priorityValue,
            isCompleted: isCompleted,
            completedAt: completedAt,
            sortOrder: sortOrder,
            reminderDate: reminderDate,
            locationReminder: locationReminder,
            recurrenceRule: recurrenceRule,
            pomodoroEstimate: pomodoroEstimate,
            pomodoroActual: pomodoroActual,
            subtasks: subtasks,
            listId: list?.id,
            tagIds: tags?.map { $0.id },
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}
