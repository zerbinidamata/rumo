import SwiftData
import Foundation

// MARK: - User Profile Model

/// Local user profile storing preferences and stats.
/// Auth data is managed by Supabase Auth.
@Model
final class UserProfile: Sendable {
    @Attribute(.unique) var id: UUID
    var supabaseUserId: String?
    var displayName: String?
    var email: String?

    // XP & Level
    var totalXP: Int
    var level: Int

    // Stats
    var perfectDaysCount: Int
    var totalHabitsCompleted: Int
    var totalTasksCompleted: Int
    var totalJournalEntries: Int
    var journalStreak: Int
    var longestJournalStreak: Int

    // Preferences
    var preferredLocale: String?
    var preferredTheme: String? // "light", "dark", "system"
    var journalBiometricEnabled: Bool
    var journalLocalOnly: Bool
    var streaksEnabled: Bool
    var notificationsEnabled: Bool

    // Pomodoro preferences
    var pomodoroDuration: Int
    var shortBreakDuration: Int
    var longBreakDuration: Int

    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        supabaseUserId: String? = nil,
        displayName: String? = nil,
        email: String? = nil
    ) {
        self.id = id
        self.supabaseUserId = supabaseUserId
        self.displayName = displayName
        self.email = email

        // XP & Level defaults
        self.totalXP = 0
        self.level = 1

        // Stats defaults
        self.perfectDaysCount = 0
        self.totalHabitsCompleted = 0
        self.totalTasksCompleted = 0
        self.totalJournalEntries = 0
        self.journalStreak = 0
        self.longestJournalStreak = 0

        // Preferences defaults
        self.preferredLocale = nil
        self.preferredTheme = "system"
        self.journalBiometricEnabled = false
        self.journalLocalOnly = false
        self.streaksEnabled = true
        self.notificationsEnabled = true

        // Pomodoro defaults
        self.pomodoroDuration = Config.defaultPomodoroDuration
        self.shortBreakDuration = Config.defaultShortBreakDuration
        self.longBreakDuration = Config.defaultLongBreakDuration

        // Timestamps
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
    }
}

// MARK: - XP & Leveling

extension UserProfile {

    /// Adds XP and recalculates level
    func addXP(_ amount: Int) {
        totalXP += amount
        level = calculateLevel(from: totalXP)
        updatedAt = Date()
    }

    /// Calculate level from XP using exponential curve
    /// Level = floor(sqrt(xp / 100))
    private func calculateLevel(from xp: Int) -> Int {
        max(1, Int(sqrt(Double(xp) / 100)))
    }

    /// XP required to reach the next level
    var xpToNextLevel: Int {
        let nextLevel = level + 1
        let xpNeeded = nextLevel * nextLevel * 100
        return max(0, xpNeeded - totalXP)
    }

    /// Progress to next level (0.0 - 1.0)
    var levelProgress: Double {
        let currentLevelXP = level * level * 100
        let nextLevelXP = (level + 1) * (level + 1) * 100
        let progressXP = totalXP - currentLevelXP
        let neededXP = nextLevelXP - currentLevelXP
        return min(1.0, max(0.0, Double(progressXP) / Double(neededXP)))
    }
}

// MARK: - Syncable Conformance

extension UserProfile: Syncable {
    static var tableName: String { "user_profiles" }
}
