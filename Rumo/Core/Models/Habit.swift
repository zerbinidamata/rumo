import SwiftData
import Foundation

// MARK: - Habit Type

enum HabitType: String, Codable, CaseIterable, Sendable {
    case good
    case bad

    var displayName: String {
        switch self {
        case .good: return String(localized: "habit.type.good")
        case .bad: return String(localized: "habit.type.bad")
        }
    }
}

// MARK: - Habit Frequency

struct HabitFrequency: Codable, Sendable, Equatable {
    enum FrequencyType: String, Codable, Sendable {
        case daily
        case weekly
        case monthly
        case custom
    }

    var type: FrequencyType
    var daysOfWeek: [Int]? // 0=Sun, 1=Mon... for weekly
    var daysOfMonth: [Int]? // 1-31 for monthly

    init(type: FrequencyType, daysOfWeek: [Int]? = nil, daysOfMonth: [Int]? = nil) {
        self.type = type
        self.daysOfWeek = daysOfWeek
        self.daysOfMonth = daysOfMonth
    }

    /// Default daily frequency
    static var daily: HabitFrequency {
        HabitFrequency(type: .daily)
    }

    /// Every weekday (Mon-Fri)
    static var weekdays: HabitFrequency {
        HabitFrequency(type: .weekly, daysOfWeek: [1, 2, 3, 4, 5])
    }
}

// MARK: - Habit Model

@Model
final class Habit: Sendable {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var color: String
    var type: HabitType
    var goalValue: Double
    var goalUnit: String
    var frequency: HabitFrequency
    var reminderTime: Date?
    var categoryId: UUID?
    var archivedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String = "✨",
        color: String = "#007AFF",
        type: HabitType = .good,
        goalValue: Double = 1,
        goalUnit: String = "vez",
        frequency: HabitFrequency = .daily,
        reminderTime: Date? = nil,
        categoryId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.color = color
        self.type = type
        self.goalValue = goalValue
        self.goalUnit = goalUnit
        self.frequency = frequency
        self.reminderTime = reminderTime
        self.categoryId = categoryId
        self.archivedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
    }
}

// MARK: - Computed Properties

extension Habit {

    var isArchived: Bool {
        archivedAt != nil
    }

    var isBinary: Bool {
        goalValue == 1
    }

    /// Checks if the habit is scheduled for a given date
    func isScheduled(for date: Date) -> Bool {
        let calendar = Calendar.current

        switch frequency.type {
        case .daily:
            return true

        case .weekly:
            guard let days = frequency.daysOfWeek else { return true }
            let weekday = calendar.component(.weekday, from: date) - 1 // 0-indexed
            return days.contains(weekday)

        case .monthly:
            guard let days = frequency.daysOfMonth else { return true }
            let day = calendar.component(.day, from: date)
            return days.contains(day)

        case .custom:
            // Custom logic would be implemented based on additional rules
            return true
        }
    }
}

// MARK: - Syncable Conformance

extension Habit: Syncable {
    static var tableName: String { "habits" }
}
