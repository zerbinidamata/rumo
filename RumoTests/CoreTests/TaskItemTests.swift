import Testing
import Foundation
@testable import Rumo

/// Tests for TaskItem model
struct TaskItemTests {

    // MARK: - Initialization Tests

    @Test("Task initializes with default values")
    func testDefaultInitialization() {
        let task = TaskItem(title: "Test Task")

        #expect(task.title == "Test Task")
        #expect(task.notes == nil)
        #expect(task.dueDate == nil)
        #expect(task.dueTime == nil)
        #expect(task.priority == .none)
        #expect(task.listId == nil)
        #expect(task.tags.isEmpty)
        #expect(task.parentId == nil)
        #expect(task.recurrence == nil)
        #expect(task.completedAt == nil)
        #expect(task.pomodoroEstimate == 0)
        #expect(task.pomodoroActual == 0)
        #expect(task.reminders.isEmpty)
        #expect(task.syncedAt == nil)
        #expect(task.deletedAt == nil)
    }

    @Test("Task initializes with custom values")
    func testCustomInitialization() {
        let dueDate = Date()
        let task = TaskItem(
            title: "Custom Task",
            notes: "Some notes",
            dueDate: dueDate,
            priority: .high,
            pomodoroEstimate: 4
        )

        #expect(task.title == "Custom Task")
        #expect(task.notes == "Some notes")
        #expect(task.dueDate == dueDate)
        #expect(task.priority == .high)
        #expect(task.pomodoroEstimate == 4)
    }

    // MARK: - Computed Properties Tests

    @Test("isCompleted returns correct value")
    func testIsCompleted() {
        let incompleteTask = TaskItem(title: "Incomplete")
        #expect(incompleteTask.isCompleted == false)

        let completeTask = TaskItem(title: "Complete", completedAt: Date())
        #expect(completeTask.isCompleted == true)
    }

    @Test("isOverdue returns correct value")
    func testIsOverdue() {
        // Task with no due date
        let noDueTask = TaskItem(title: "No Due")
        #expect(noDueTask.isOverdue == false)

        // Task due in the past
        let pastTask = TaskItem(
            title: "Past",
            dueDate: Date().addingTimeInterval(-86400) // Yesterday
        )
        #expect(pastTask.isOverdue == true)

        // Task due in the future
        let futureTask = TaskItem(
            title: "Future",
            dueDate: Date().addingTimeInterval(86400) // Tomorrow
        )
        #expect(futureTask.isOverdue == false)

        // Completed task (even if past due)
        let completedPastTask = TaskItem(
            title: "Completed Past",
            dueDate: Date().addingTimeInterval(-86400),
            completedAt: Date()
        )
        #expect(completedPastTask.isOverdue == false)
    }

    @Test("isRecurring returns correct value")
    func testIsRecurring() {
        let nonRecurring = TaskItem(title: "One-time")
        #expect(nonRecurring.isRecurring == false)

        let recurring = TaskItem(
            title: "Recurring",
            recurrence: RecurrenceRule(frequency: .daily)
        )
        #expect(recurring.isRecurring == true)
    }

    // MARK: - Syncable Tests

    @Test("Task conforms to Syncable")
    func testSyncableConformance() {
        var task = TaskItem(title: "Syncable Test")

        #expect(task.needsSync == true) // Never synced
        #expect(task.isDeleted == false)
        #expect(TaskItem.tableName == "task_items")

        task.markAsSynced()
        #expect(task.syncedAt != nil)
        #expect(task.needsSync == false)

        task.markAsDeleted()
        #expect(task.isDeleted == true)
        #expect(task.deletedAt != nil)
    }
}

// MARK: - TaskPriority Tests

struct TaskPriorityTests {

    @Test("Priority has correct raw values")
    func testRawValues() {
        #expect(TaskPriority.none.rawValue == 0)
        #expect(TaskPriority.low.rawValue == 1)
        #expect(TaskPriority.medium.rawValue == 2)
        #expect(TaskPriority.high.rawValue == 3)
    }

    @Test("Priority has display names")
    func testDisplayNames() {
        #expect(!TaskPriority.none.displayName.isEmpty)
        #expect(!TaskPriority.high.displayName.isEmpty)
    }

    @Test("Priority has colors")
    func testColors() {
        #expect(TaskPriority.none.color.hasPrefix("#"))
        #expect(TaskPriority.high.color.hasPrefix("#"))
    }
}

// MARK: - RecurrenceRule Tests

struct RecurrenceRuleTests {

    @Test("RecurrenceRule initializes correctly")
    func testInitialization() {
        let daily = RecurrenceRule(frequency: .daily)
        #expect(daily.frequency == .daily)
        #expect(daily.interval == 1)
        #expect(daily.daysOfWeek == nil)
        #expect(daily.endsAt == nil)

        let weekly = RecurrenceRule(
            frequency: .weekly,
            interval: 2,
            daysOfWeek: [1, 3, 5]
        )
        #expect(weekly.frequency == .weekly)
        #expect(weekly.interval == 2)
        #expect(weekly.daysOfWeek == [1, 3, 5])
    }

    @Test("RecurrenceRule is Codable")
    func testCodable() throws {
        let rule = RecurrenceRule(
            frequency: .monthly,
            interval: 1,
            endsAt: Date()
        )

        let encoded = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(RecurrenceRule.self, from: encoded)

        #expect(decoded.frequency == rule.frequency)
        #expect(decoded.interval == rule.interval)
    }
}

// MARK: - TaskReminder Tests

struct TaskReminderTests {

    @Test("TaskReminder initializes correctly")
    func testInitialization() {
        let reminder = TaskReminder(offsetMinutes: -60)

        #expect(reminder.offsetMinutes == -60) // 1 hour before
        #expect(reminder.locationTrigger == nil)
    }

    @Test("TaskReminder with location trigger")
    func testLocationTrigger() {
        let location = TaskReminder.LocationTrigger(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 100,
            onEntry: true,
            placeName: "Office"
        )

        let reminder = TaskReminder(
            offsetMinutes: 0,
            locationTrigger: location
        )

        #expect(reminder.locationTrigger != nil)
        #expect(reminder.locationTrigger?.placeName == "Office")
        #expect(reminder.locationTrigger?.onEntry == true)
    }
}
