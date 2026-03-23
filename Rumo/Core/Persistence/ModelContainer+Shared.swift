import SwiftData
import Foundation

// MARK: - Model Container Extension

extension ModelContainer {

    /// Shared model container configured with App Group for widget access.
    /// Uses a static property to ensure single instance across the app.
    static let shared: ModelContainer = {
        do {
            let schema = Schema([
                // Tasks
                TaskItem.self,
                TaskList.self,
                TaskTag.self,

                // Habits
                Habit.self,
                HabitLog.self,
                HabitCategory.self,
                Achievement.self,

                // Journal
                JournalEntry.self,
                JournalPrompt.self,

                // Sync
                PendingSyncOperation.self,

                // User
                UserProfile.self,
            ])

            let modelConfiguration = ModelConfiguration(
                "Rumo",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier(Config.appGroupIdentifier)
            )

            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // This is a fatal error because the app cannot function without persistence
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()

    /// In-memory container for previews and testing
    @MainActor
    static let preview: ModelContainer = {
        do {
            let schema = Schema([
                TaskItem.self,
                TaskList.self,
                TaskTag.self,
                Habit.self,
                HabitLog.self,
                HabitCategory.self,
                Achievement.self,
                JournalEntry.self,
                JournalPrompt.self,
                PendingSyncOperation.self,
                UserProfile.self,
            ])

            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: true
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Insert sample data for previews
            insertPreviewData(into: container.mainContext)

            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error.localizedDescription)")
        }
    }()

    /// Inserts sample data for SwiftUI previews
    @MainActor
    private static func insertPreviewData(into context: ModelContext) {
        // Sample task list
        let inbox = TaskList(
            id: UUID(),
            name: "Inbox",
            color: "#007AFF",
            icon: "tray.fill",
            sortOrder: 0,
            isSmartList: false
        )
        context.insert(inbox)

        // Sample tasks
        let task1 = TaskItem(
            id: UUID(),
            title: "Reunião com cliente",
            dueDate: Date().addingTimeInterval(3600),
            priority: .high
        )
        context.insert(task1)

        let task2 = TaskItem(
            id: UUID(),
            title: "Revisar proposta",
            dueDate: Date().addingTimeInterval(86400),
            priority: .medium
        )
        context.insert(task2)

        // Sample habits
        let habit1 = Habit(
            id: UUID(),
            name: "Meditação",
            emoji: "🧘",
            color: "#34C759",
            type: .good,
            goalValue: 1,
            goalUnit: "vez"
        )
        context.insert(habit1)

        let habit2 = Habit(
            id: UUID(),
            name: "Beber água",
            emoji: "💧",
            color: "#007AFF",
            type: .good,
            goalValue: 8,
            goalUnit: "copos"
        )
        context.insert(habit2)

        // Sample journal entry
        let entry = JournalEntry(
            id: UUID(),
            date: Date(),
            bodyEncrypted: Data(),
            bodyHash: "",
            mood: .good,
            wordCount: 150
        )
        context.insert(entry)

        try? context.save()
    }
}
