#if os(macOS)
import AppKit
import UserNotifications

/// macOS App Delegate for handling system-level events
final class MacAppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure notifications
        configureNotifications()

        // Register for remote notifications
        NSApplication.shared.registerForRemoteNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup before app terminates
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running even when all windows are closed (menu bar presence)
        return false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Reset badge count when app becomes active
        NSApplication.shared.dockTile.badgeLabel = nil
    }

    // MARK: - Remote Notifications

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")

        // Send token to Supabase for push notifications
        Task {
            // await SupabaseManager.shared.registerDeviceToken(token)
        }
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - URL Handling

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleIncomingURL(url)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // Handle deep links (magic link callbacks, etc.)
        NotificationCenter.default.post(
            name: .handleIncomingURL,
            object: nil,
            userInfo: ["url": url]
        )
    }

    // MARK: - Private Methods

    private func configureNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Define notification categories
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: String(localized: "notification.action.complete"),
            options: .foreground
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: String(localized: "notification.action.snooze"),
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: []
        )

        let habitCategory = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: []
        )

        center.setNotificationCategories([taskCategory, habitCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension MacAppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notifications even when app is in foreground
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case "COMPLETE_ACTION":
            handleCompleteAction(userInfo: userInfo)
        case "SNOOZE_ACTION":
            handleSnoozeAction(userInfo: userInfo)
        default:
            // Default tap - open relevant item
            handleDefaultAction(userInfo: userInfo)
        }
    }

    private func handleCompleteAction(userInfo: [AnyHashable: Any]) {
        if let taskId = userInfo["taskId"] as? String {
            NotificationCenter.default.post(
                name: .completeTaskFromNotification,
                object: nil,
                userInfo: ["taskId": taskId]
            )
        } else if let habitId = userInfo["habitId"] as? String {
            NotificationCenter.default.post(
                name: .completeHabitFromNotification,
                object: nil,
                userInfo: ["habitId": habitId]
            )
        }
    }

    private func handleSnoozeAction(userInfo: [AnyHashable: Any]) {
        // Reschedule notification for 1 hour later
        if let taskId = userInfo["taskId"] as? String {
            NotificationCenter.default.post(
                name: .snoozeTaskNotification,
                object: nil,
                userInfo: ["taskId": taskId]
            )
        }
    }

    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        if let taskId = userInfo["taskId"] as? String {
            NotificationCenter.default.post(
                name: .navigateToTask,
                object: nil,
                userInfo: ["taskId": taskId]
            )
        } else if let habitId = userInfo["habitId"] as? String {
            NotificationCenter.default.post(
                name: .navigateToHabit,
                object: nil,
                userInfo: ["habitId": habitId]
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let handleIncomingURL = Notification.Name("handleIncomingURL")
    static let completeTaskFromNotification = Notification.Name("completeTaskFromNotification")
    static let completeHabitFromNotification = Notification.Name("completeHabitFromNotification")
    static let snoozeTaskNotification = Notification.Name("snoozeTaskNotification")
}
#endif
