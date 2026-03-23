import Foundation
import UserNotifications
import CoreLocation

// MARK: - Task Reminder Types

/// Represents a reminder for a task
struct TaskReminder: Codable, Identifiable, Sendable {
    let id: UUID
    var offsetMinutes: Int  // Minutes before due date (-60 = 1 hour before)
    var locationTrigger: LocationTrigger?

    init(id: UUID = UUID(), offsetMinutes: Int = -15, locationTrigger: LocationTrigger? = nil) {
        self.id = id
        self.offsetMinutes = offsetMinutes
        self.locationTrigger = locationTrigger
    }
}

/// Location-based trigger for a reminder
struct LocationTrigger: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let radius: Double  // In meters
    let onEntry: Bool   // true = trigger on entry, false = trigger on exit
    let name: String?

    init(latitude: Double, longitude: Double, radius: Double = 100, onEntry: Bool = true, name: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.onEntry = onEntry
        self.name = name
    }
}

/// Service for managing local and push notifications.
/// Handles task reminders, habit reminders, and journal prompts.
@MainActor
final class NotificationService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Published State

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Dependencies

    private let center: UNUserNotificationCenter

    // MARK: - Initialization

    private override init() {
        self.center = .current()
        super.init()
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Requests notification authorization
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await center.requestAuthorization(options: options)
        await checkAuthorizationStatus()
        return granted
    }

    /// Checks current authorization status
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Task Reminders

    /// Schedules a reminder for a task
    func scheduleTaskReminder(
        task: TaskItem,
        reminder: TaskReminder
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.task.title")
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = [
            "taskId": task.id.uuidString,
            "reminderId": reminder.id.uuidString
        ]

        // Add task ID for action handling
        content.targetContentIdentifier = task.id.uuidString

        let trigger: UNNotificationTrigger

        if let locationTrigger = reminder.locationTrigger {
            // Location-based reminder
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(
                    latitude: locationTrigger.latitude,
                    longitude: locationTrigger.longitude
                ),
                radius: locationTrigger.radius,
                identifier: reminder.id.uuidString
            )
            region.notifyOnEntry = locationTrigger.onEntry
            region.notifyOnExit = !locationTrigger.onEntry

            trigger = UNLocationNotificationTrigger(region: region, repeats: false)

        } else if let dueDate = task.dueDate {
            // Time-based reminder
            let reminderDate = dueDate.addingTimeInterval(TimeInterval(reminder.offsetMinutes * 60))
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        } else {
            throw NotificationError.noTriggerDate
        }

        let request = UNNotificationRequest(
            identifier: "task-\(task.id)-\(reminder.id)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Cancels all reminders for a task
    func cancelTaskReminders(taskId: UUID) {
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.hasPrefix("task-\(taskId)") }
                .map { $0.identifier }

            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    // MARK: - Habit Reminders

    /// Schedules a daily reminder for a habit
    func scheduleHabitReminder(habit: Habit) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        guard let reminderTime = habit.reminderTime else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) \(habit.name)"
        content.body = String(localized: "notification.habit.body")
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = ["habitId": habit.id.uuidString]
        content.targetContentIdentifier = habit.id.uuidString

        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: reminderTime
        )

        // Schedule based on frequency
        switch habit.frequency.type {
        case .daily:
            // Repeat every day at the same time
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )
            let request = UNNotificationRequest(
                identifier: "habit-\(habit.id)",
                content: content,
                trigger: trigger
            )
            try await center.add(request)

        case .weekly:
            // Schedule for each day of the week
            if let days = habit.frequency.daysOfWeek {
                for day in days {
                    var dayComponents = components
                    dayComponents.weekday = day + 1 // Calendar uses 1-indexed

                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: dayComponents,
                        repeats: true
                    )
                    let request = UNNotificationRequest(
                        identifier: "habit-\(habit.id)-day\(day)",
                        content: content,
                        trigger: trigger
                    )
                    try await center.add(request)
                }
            }

        case .monthly, .custom:
            // For monthly/custom, schedule next occurrence only
            // Will be rescheduled when completed
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "habit-\(habit.id)",
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }
    }

    /// Cancels all reminders for a habit
    func cancelHabitReminders(habitId: UUID) {
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.hasPrefix("habit-\(habitId)") }
                .map { $0.identifier }

            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    // MARK: - Journal Reminders

    /// Schedules a daily journal reminder
    func scheduleJournalReminder(at time: Date) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        // Cancel existing journal reminder
        center.removePendingNotificationRequests(withIdentifiers: ["journal-daily"])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.journal.title")
        content.body = String(localized: "notification.journal.body")
        content.sound = .default
        content.categoryIdentifier = "JOURNAL_REMINDER"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "journal-daily",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Cancels the journal reminder
    func cancelJournalReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["journal-daily"])
    }

    // MARK: - Insight Notifications

    /// Schedules an insight notification
    func scheduleInsightNotification(
        title: String,
        body: String,
        delay: TimeInterval = 0
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "INSIGHT"

        let trigger: UNNotificationTrigger
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            // Schedule for 1 second from now (minimum)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: "insight-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Badge Management

    /// Updates the app badge with pending count
    func updateBadge(count: Int) {
        center.setBadgeCount(count)
    }

    /// Clears the app badge
    func clearBadge() {
        center.setBadgeCount(0)
    }

    // MARK: - Utilities

    /// Gets all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    /// Cancels all pending notifications
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}

// MARK: - Notification Error

enum NotificationError: LocalizedError {
    case notAuthorized
    case noTriggerDate
    case schedulingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return String(localized: "error.notification.notAuthorized")
        case .noTriggerDate:
            return String(localized: "error.notification.noTriggerDate")
        case .schedulingFailed:
            return String(localized: "error.notification.schedulingFailed")
        }
    }
}

// MARK: - Notification Delegate Handler

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Handles notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "COMPLETE_TASK":
            if let taskIdString = userInfo["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                await handleCompleteTask(taskId)
            }

        case "SNOOZE_TASK":
            if let taskIdString = userInfo["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                await handleSnoozeTask(taskId)
            }

        case "COMPLETE_HABIT":
            if let habitIdString = userInfo["habitId"] as? String,
               let habitId = UUID(uuidString: habitIdString) {
                await handleCompleteHabit(habitId)
            }

        case "SKIP_HABIT":
            if let habitIdString = userInfo["habitId"] as? String,
               let habitId = UUID(uuidString: habitIdString) {
                await handleSkipHabit(habitId)
            }

        default:
            break
        }
    }

    /// Handles foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    // MARK: - Action Handlers

    private func handleCompleteTask(_ taskId: UUID) async {
        // Will be implemented with task completion logic
    }

    private func handleSnoozeTask(_ taskId: UUID) async {
        // Reschedule for 1 hour later
    }

    private func handleCompleteHabit(_ habitId: UUID) async {
        // Will be implemented with habit completion logic
    }

    private func handleSkipHabit(_ habitId: UUID) async {
        // Will be implemented with habit skip logic
    }
}
