import UIKit
import UserNotifications

/// UIKit App Delegate for handling lifecycle events that SwiftUI doesn't expose.
/// Used for push notifications, background tasks, and Siri shortcuts.
final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure notification categories for interactive notifications
        configureNotificationCategories()

        // Register for remote notifications
        registerForRemoteNotifications(application)

        // Configure background tasks
        registerBackgroundTasks()

        return true
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Send device token to Supabase for push notifications
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            await registerDeviceToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Log error but don't crash - notifications are optional
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - URL Handling

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle custom URL schemes
        // Delegate to AppCoordinator via notification or direct reference
        NotificationCenter.default.post(
            name: .didReceiveDeepLink,
            object: nil,
            userInfo: ["url": url]
        )
        return true
    }

    // MARK: - Universal Links

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        NotificationCenter.default.post(
            name: .didReceiveDeepLink,
            object: nil,
            userInfo: ["url": url]
        )
        return true
    }

    // MARK: - Private Methods

    private func configureNotificationCategories() {
        // Task reminder actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: String(localized: "notification.action.complete"),
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_TASK",
            title: String(localized: "notification.action.snooze"),
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Habit reminder actions
        let completeHabitAction = UNNotificationAction(
            identifier: "COMPLETE_HABIT",
            title: String(localized: "notification.action.complete"),
            options: [.foreground]
        )

        let skipHabitAction = UNNotificationAction(
            identifier: "SKIP_HABIT",
            title: String(localized: "notification.action.skip"),
            options: []
        )

        let habitCategory = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [completeHabitAction, skipHabitAction],
            intentIdentifiers: [],
            options: []
        )

        // Journal reminder
        let journalCategory = UNNotificationCategory(
            identifier: "JOURNAL_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            taskCategory,
            habitCategory,
            journalCategory
        ])
    }

    private func registerForRemoteNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            guard granted else { return }

            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    private func registerBackgroundTasks() {
        // Register background tasks for sync and weekly review
        // BGTaskScheduler.shared.register(...)
        // Will be implemented in Phase 3
    }

    private func registerDeviceToken(_ token: String) async {
        // Send to Supabase - will be implemented in Phase 3
        print("Device token: \(token)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let didReceiveDeepLink = Notification.Name("didReceiveDeepLink")
}
