import SwiftData
import Foundation

// MARK: - Achievement Type

enum AchievementType: String, Codable, CaseIterable, Sendable {
    // Habits
    case firstStep          // ACH-01: Create first habit
    case perfectWeek        // ACH-02: 7-day streak
    case monthUnbeaten      // ACH-03: 30-day streak
    case centurion          // ACH-04: 100-day streak
    case perfectDay         // ACH-05: All habits complete in a day
    case tenPerfectDays     // ACH-06: 10 perfect days accumulated
    case earlyBird          // ACH-07: Habit before 8am
    case honest             // ACH-08: Mark habit as failed with note

    // Journal
    case writer             // ACH-09: 10 journal entries
    case reflective         // ACH-10: 30 journal entries

    // Tasks
    case totalFocus         // ACH-11: 5 Pomodoro sessions

    // Cross-pillar
    case tripleDay          // ACH-12: Habits + priority task + journal same day
    case integratedWeek     // ACH-13: Triple day for 7 consecutive days

    var displayName: String {
        switch self {
        case .firstStep: return String(localized: "achievement.firstStep.name")
        case .perfectWeek: return String(localized: "achievement.perfectWeek.name")
        case .monthUnbeaten: return String(localized: "achievement.monthUnbeaten.name")
        case .centurion: return String(localized: "achievement.centurion.name")
        case .perfectDay: return String(localized: "achievement.perfectDay.name")
        case .tenPerfectDays: return String(localized: "achievement.tenPerfectDays.name")
        case .earlyBird: return String(localized: "achievement.earlyBird.name")
        case .honest: return String(localized: "achievement.honest.name")
        case .writer: return String(localized: "achievement.writer.name")
        case .reflective: return String(localized: "achievement.reflective.name")
        case .totalFocus: return String(localized: "achievement.totalFocus.name")
        case .tripleDay: return String(localized: "achievement.tripleDay.name")
        case .integratedWeek: return String(localized: "achievement.integratedWeek.name")
        }
    }

    var description: String {
        switch self {
        case .firstStep: return String(localized: "achievement.firstStep.description")
        case .perfectWeek: return String(localized: "achievement.perfectWeek.description")
        case .monthUnbeaten: return String(localized: "achievement.monthUnbeaten.description")
        case .centurion: return String(localized: "achievement.centurion.description")
        case .perfectDay: return String(localized: "achievement.perfectDay.description")
        case .tenPerfectDays: return String(localized: "achievement.tenPerfectDays.description")
        case .earlyBird: return String(localized: "achievement.earlyBird.description")
        case .honest: return String(localized: "achievement.honest.description")
        case .writer: return String(localized: "achievement.writer.description")
        case .reflective: return String(localized: "achievement.reflective.description")
        case .totalFocus: return String(localized: "achievement.totalFocus.description")
        case .tripleDay: return String(localized: "achievement.tripleDay.description")
        case .integratedWeek: return String(localized: "achievement.integratedWeek.description")
        }
    }

    var icon: String {
        switch self {
        case .firstStep: return "flag.fill"
        case .perfectWeek: return "7.circle.fill"
        case .monthUnbeaten: return "calendar.badge.checkmark"
        case .centurion: return "crown.fill"
        case .perfectDay: return "star.fill"
        case .tenPerfectDays: return "sparkles"
        case .earlyBird: return "sunrise.fill"
        case .honest: return "hand.raised.fill"
        case .writer: return "pencil.circle.fill"
        case .reflective: return "brain.head.profile"
        case .totalFocus: return "timer"
        case .tripleDay: return "triangle.fill"
        case .integratedWeek: return "square.stack.3d.up.fill"
        }
    }

    var xpReward: Int {
        switch self {
        case .firstStep: return 50
        case .perfectWeek: return 100
        case .monthUnbeaten: return 300
        case .centurion: return 1000
        case .perfectDay: return 75
        case .tenPerfectDays: return 200
        case .earlyBird: return 50
        case .honest: return 25
        case .writer: return 100
        case .reflective: return 250
        case .totalFocus: return 100
        case .tripleDay: return 150
        case .integratedWeek: return 500
        }
    }

    var pilar: Pilar {
        switch self {
        case .firstStep, .perfectWeek, .monthUnbeaten, .centurion,
             .perfectDay, .tenPerfectDays, .earlyBird, .honest:
            return .habits
        case .writer, .reflective:
            return .journal
        case .totalFocus:
            return .tasks
        case .tripleDay, .integratedWeek:
            return .crossPillar
        }
    }
}

// MARK: - Pilar

enum Pilar: String, Codable, Sendable, CaseIterable, Hashable {
    case tasks
    case habits
    case journal
    case crossPillar
}

// MARK: - Achievement Model

@Model
final class Achievement: Sendable {
    @Attribute(.unique) var id: UUID
    var type: AchievementType
    var habitId: UUID? // nil for global/cross-pillar achievements
    var unlockedAt: Date
    var seenAt: Date?
    var syncedAt: Date?
    var deletedAt: Date?

    // Computed for Syncable
    var createdAt: Date { unlockedAt }
    var updatedAt: Date {
        get { seenAt ?? unlockedAt }
        set { }
    }

    init(
        id: UUID = UUID(),
        type: AchievementType,
        habitId: UUID? = nil,
        unlockedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.habitId = habitId
        self.unlockedAt = unlockedAt
        self.seenAt = nil
        self.syncedAt = nil
        self.deletedAt = nil
    }
}

// MARK: - Computed Properties

extension Achievement {

    var hasBeenSeen: Bool {
        seenAt != nil
    }

    func markAsSeen() {
        seenAt = Date()
    }
}

// MARK: - Syncable Conformance

extension Achievement: Syncable {
    static var tableName: String { "achievements" }
}
