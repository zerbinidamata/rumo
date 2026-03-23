import SwiftData
import Foundation

// MARK: - Habit Category Model

@Model
final class HabitCategory: Sendable {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        color: String = "#8E8E93",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
    }
}

// MARK: - Syncable Conformance

extension HabitCategory: Syncable {
    static var tableName: String { "habit_categories" }
}

// MARK: - Default Categories

extension HabitCategory {

    static func createDefaultCategories() -> [HabitCategory] {
        [
            HabitCategory(
                name: String(localized: "habit.category.health"),
                icon: "heart.fill",
                color: "#FF3B30",
                sortOrder: 0
            ),
            HabitCategory(
                name: String(localized: "habit.category.productivity"),
                icon: "bolt.fill",
                color: "#FF9500",
                sortOrder: 1
            ),
            HabitCategory(
                name: String(localized: "habit.category.mindfulness"),
                icon: "brain.head.profile",
                color: "#AF52DE",
                sortOrder: 2
            ),
            HabitCategory(
                name: String(localized: "habit.category.fitness"),
                icon: "figure.run",
                color: "#34C759",
                sortOrder: 3
            ),
            HabitCategory(
                name: String(localized: "habit.category.learning"),
                icon: "book.fill",
                color: "#007AFF",
                sortOrder: 4
            ),
        ]
    }
}
