import SwiftData
import Foundation

// MARK: - Habit Status

enum HabitStatus: String, Codable, CaseIterable, Sendable {
    case completed
    case failed
    case skipped

    var displayName: String {
        switch self {
        case .completed: return String(localized: "habit.status.completed")
        case .failed: return String(localized: "habit.status.failed")
        case .skipped: return String(localized: "habit.status.skipped")
        }
    }

    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
}

// MARK: - Habit Log Model

@Model
final class HabitLog: Sendable {
    @Attribute(.unique) var id: UUID
    var habitId: UUID
    var date: Date
    var value: Double
    var status: HabitStatus
    var note: String?
    var createdAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    // Computed updatedAt for Syncable conformance
    var updatedAt: Date {
        get { createdAt }
        set { }
    }

    init(
        id: UUID = UUID(),
        habitId: UUID,
        date: Date,
        value: Double = 1,
        status: HabitStatus = .completed,
        note: String? = nil
    ) {
        self.id = id
        self.habitId = habitId
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.status = status
        self.note = note
        self.createdAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
    }
}

// MARK: - Syncable Conformance

extension HabitLog: Syncable {
    static var tableName: String { "habit_logs" }
}
