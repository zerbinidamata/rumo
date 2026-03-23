import Foundation

/// App configuration values loaded from xcconfig files.
/// Values are injected via Info.plist at build time.
enum Config {

    // MARK: - Bundle Info

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.rumo.app"
    }

    // MARK: - Supabase

    static var supabaseURL: String {
        guard let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              !url.isEmpty,
              url != "$(SUPABASE_URL)" else {
            #if DEBUG
            fatalError("SUPABASE_URL not configured. Check your xcconfig files.")
            #else
            return ""
            #endif
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !key.isEmpty,
              key != "$(SUPABASE_ANON_KEY)" else {
            #if DEBUG
            fatalError("SUPABASE_ANON_KEY not configured. Check your xcconfig files.")
            #else
            return ""
            #endif
        }
        return key
    }

    // MARK: - Sentry

    static var sentryDSN: String? {
        guard let dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String,
              !dsn.isEmpty,
              dsn != "$(SENTRY_DSN)" else {
            return nil
        }
        return dsn
    }

    // MARK: - App Group

    static let appGroupIdentifier = "group.com.rumo.app"

    // MARK: - Feature Flags

    #if DEBUG
    static let isDebug = true
    /// Set to true to skip authentication during development
    static let bypassAuth = true
    #else
    static let isDebug = false
    static let bypassAuth = false
    #endif

    // MARK: - Default Values

    /// Default Pomodoro duration in minutes
    static let defaultPomodoroDuration = 25

    /// Default short break duration in minutes
    static let defaultShortBreakDuration = 5

    /// Default long break duration in minutes
    static let defaultLongBreakDuration = 15

    /// Maximum number of habits for free tier
    static let freeHabitLimit = 3

    /// Maximum reminders per task
    static let maxRemindersPerTask = 5

    /// Auto-save interval for journal in seconds
    static let journalAutoSaveInterval: TimeInterval = 10

    /// Maximum image size before compression (in bytes)
    static let maxImageSizeBytes = 2 * 1024 * 1024 // 2MB

    /// Target image size after compression (in bytes)
    static let targetImageSizeBytes = 1 * 1024 * 1024 // 1MB
}

// MARK: - Environment

extension Config {

    enum Environment {
        case debug
        case release

        static var current: Environment {
            #if DEBUG
            return .debug
            #else
            return .release
            #endif
        }
    }
}
