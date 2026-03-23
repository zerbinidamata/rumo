import Foundation
import SwiftData

/// Manages user profile creation and updates
@MainActor
final class ProfileManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ProfileManager()

    // MARK: - Published State

    @Published private(set) var currentProfile: UserProfile?

    // MARK: - Dependencies

    private let modelContainer: ModelContainer

    // MARK: - Initialization

    private init(modelContainer: ModelContainer = .shared) {
        self.modelContainer = modelContainer
    }

    // MARK: - Profile Operations

    /// Creates or updates the user profile after authentication
    func createOrUpdateProfile(for user: User) async {
        let context = ModelContext(modelContainer)

        // Check if profile exists
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        let existingProfile = profiles.first { $0.supabaseUserId == user.id }

        if let profile = existingProfile {
            // Update existing profile
            profile.email = user.email
            profile.displayName = user.displayName ?? profile.displayName
            profile.updatedAt = Date()
            currentProfile = profile
        } else {
            // Create new profile
            let newProfile = UserProfile(
                supabaseUserId: user.id,
                displayName: user.displayName,
                email: user.email
            )
            context.insert(newProfile)
            currentProfile = newProfile

            // Create default data for new user
            await createDefaultData(for: newProfile, context: context)
        }

        try? context.save()
    }

    /// Loads the current user's profile
    func loadProfile(for userId: String) async -> UserProfile? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        let profile = profiles.first { $0.supabaseUserId == userId }
        currentProfile = profile
        return profile
    }

    /// Updates profile preferences
    func updatePreferences(
        theme: String? = nil,
        journalBiometric: Bool? = nil,
        journalLocalOnly: Bool? = nil,
        streaksEnabled: Bool? = nil,
        notificationsEnabled: Bool? = nil,
        pomodoroDuration: Int? = nil,
        shortBreakDuration: Int? = nil,
        longBreakDuration: Int? = nil
    ) async {
        guard let profile = currentProfile else { return }

        let context = ModelContext(modelContainer)

        if let theme = theme {
            profile.preferredTheme = theme
        }
        if let journalBiometric = journalBiometric {
            profile.journalBiometricEnabled = journalBiometric
        }
        if let journalLocalOnly = journalLocalOnly {
            profile.journalLocalOnly = journalLocalOnly
        }
        if let streaksEnabled = streaksEnabled {
            profile.streaksEnabled = streaksEnabled
        }
        if let notificationsEnabled = notificationsEnabled {
            profile.notificationsEnabled = notificationsEnabled
        }
        if let pomodoroDuration = pomodoroDuration {
            profile.pomodoroDuration = pomodoroDuration
        }
        if let shortBreakDuration = shortBreakDuration {
            profile.shortBreakDuration = shortBreakDuration
        }
        if let longBreakDuration = longBreakDuration {
            profile.longBreakDuration = longBreakDuration
        }

        profile.updatedAt = Date()
        try? context.save()
    }

    /// Adds XP to the current profile
    func addXP(_ amount: Int) async {
        guard let profile = currentProfile else { return }

        let previousLevel = profile.level
        profile.addXP(amount)

        let context = ModelContext(modelContainer)
        try? context.save()

        // Check for level up
        if profile.level > previousLevel {
            NotificationCenter.default.post(
                name: .didLevelUp,
                object: nil,
                userInfo: [
                    "previousLevel": previousLevel,
                    "newLevel": profile.level
                ]
            )
        }
    }

    /// Increments a stat counter
    func incrementStat(_ stat: ProfileStat) async {
        guard let profile = currentProfile else { return }

        let context = ModelContext(modelContainer)

        switch stat {
        case .perfectDay:
            profile.perfectDaysCount += 1
        case .habitCompleted:
            profile.totalHabitsCompleted += 1
        case .taskCompleted:
            profile.totalTasksCompleted += 1
        case .journalEntry:
            profile.totalJournalEntries += 1
            profile.journalStreak += 1
            if profile.journalStreak > profile.longestJournalStreak {
                profile.longestJournalStreak = profile.journalStreak
            }
        }

        profile.updatedAt = Date()
        try? context.save()
    }

    /// Resets journal streak (called when user misses a day)
    func resetJournalStreak() async {
        guard let profile = currentProfile else { return }

        let context = ModelContext(modelContainer)
        profile.journalStreak = 0
        profile.updatedAt = Date()
        try? context.save()
    }

    /// Clears all profile data (for account deletion)
    func clearProfile() async {
        guard let profile = currentProfile else { return }

        let context = ModelContext(modelContainer)
        context.delete(profile)
        try? context.save()

        currentProfile = nil
    }

    // MARK: - Private Methods

    /// Creates default data for new users
    private func createDefaultData(for profile: UserProfile, context: ModelContext) async {
        // Create default task lists
        let defaultLists = TaskList.createDefaultLists()
        for list in defaultLists {
            context.insert(list)
        }

        // Create default habit categories
        let defaultCategories = HabitCategory.createDefaultCategories()
        for category in defaultCategories {
            context.insert(category)
        }

        // Create default journal prompts
        let defaultPrompts = JournalPrompt.createDefaultPrompts()
        for prompt in defaultPrompts {
            context.insert(prompt)
        }

        try? context.save()
    }
}

// MARK: - Profile Stats

enum ProfileStat {
    case perfectDay
    case habitCompleted
    case taskCompleted
    case journalEntry
}

// MARK: - Notification Names

extension Notification.Name {
    static let didLevelUp = Notification.Name("didLevelUp")
}
