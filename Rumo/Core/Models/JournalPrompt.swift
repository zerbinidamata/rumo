import SwiftData
import Foundation

// MARK: - Prompt Category

enum PromptCategory: String, Codable, CaseIterable, Sendable {
    case gratitude
    case reflection
    case planning
    case celebration
    case hard

    var displayName: String {
        switch self {
        case .gratitude: return String(localized: "prompt.category.gratitude")
        case .reflection: return String(localized: "prompt.category.reflection")
        case .planning: return String(localized: "prompt.category.planning")
        case .celebration: return String(localized: "prompt.category.celebration")
        case .hard: return String(localized: "prompt.category.hard")
        }
    }

    var icon: String {
        switch self {
        case .gratitude: return "heart.fill"
        case .reflection: return "brain.head.profile"
        case .planning: return "calendar.badge.plus"
        case .celebration: return "party.popper.fill"
        case .hard: return "cloud.rain.fill"
        }
    }
}

// MARK: - Prompt Trigger

struct PromptTrigger: Codable, Sendable, Equatable {
    enum TriggerType: String, Codable, Sendable {
        case allHabitsComplete
        case habitFailed
        case taskCompleted
        case moodBadOrAwful
        case monday
        case sunday
        case overdueTasks
        case streakMilestone
        case noCondition
    }

    var type: TriggerType
    var parameters: [String: String]? // Additional context

    init(type: TriggerType, parameters: [String: String]? = nil) {
        self.type = type
        self.parameters = parameters
    }
}

// MARK: - Journal Prompt Model

@Model
final class JournalPrompt: Sendable {
    @Attribute(.unique) var id: UUID
    var textPtBR: String
    var textEn: String
    var category: PromptCategory
    var contextTrigger: PromptTrigger?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        textPtBR: String,
        textEn: String,
        category: PromptCategory,
        contextTrigger: PromptTrigger? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.textPtBR = textPtBR
        self.textEn = textEn
        self.category = category
        self.contextTrigger = contextTrigger
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
    }

    /// Returns the localized text based on current locale
    var localizedText: String {
        Locale.current.language.languageCode?.identifier == "pt" ? textPtBR : textEn
    }
}

// MARK: - Syncable Conformance

extension JournalPrompt: Syncable {
    static var tableName: String { "journal_prompts" }
}

// MARK: - Default Prompts

extension JournalPrompt {

    static func createDefaultPrompts() -> [JournalPrompt] {
        [
            // Gratitude
            JournalPrompt(
                textPtBR: "Três coisas pelas quais você é grato hoje.",
                textEn: "Three things you're grateful for today.",
                category: .gratitude,
                contextTrigger: PromptTrigger(type: .noCondition)
            ),

            // Celebration - All habits complete
            JournalPrompt(
                textPtBR: "Você foi consistente hoje. O que tornou isso possível?",
                textEn: "You were consistent today. What made that possible?",
                category: .celebration,
                contextTrigger: PromptTrigger(type: .allHabitsComplete)
            ),

            // Reflection - Habit failed
            JournalPrompt(
                textPtBR: "Algo atrapalhou um hábito hoje. O que você aprendeu sobre si mesmo?",
                textEn: "Something got in the way of a habit today. What did you learn about yourself?",
                category: .reflection,
                contextTrigger: PromptTrigger(type: .habitFailed)
            ),

            // Celebration - Task completed
            JournalPrompt(
                textPtBR: "Você completou algo importante. Como você se sente sobre isso?",
                textEn: "You completed something important. How do you feel about it?",
                category: .celebration,
                contextTrigger: PromptTrigger(type: .taskCompleted)
            ),

            // Hard - Bad mood
            JournalPrompt(
                textPtBR: "Parece que foi um dia difícil. O que pesou mais?",
                textEn: "Seems like it was a hard day. What weighed on you the most?",
                category: .hard,
                contextTrigger: PromptTrigger(type: .moodBadOrAwful)
            ),

            // Planning - Monday
            JournalPrompt(
                textPtBR: "Nova semana. O que você quer proteger nessa semana?",
                textEn: "New week. What do you want to protect this week?",
                category: .planning,
                contextTrigger: PromptTrigger(type: .monday)
            ),

            // Reflection - Sunday
            JournalPrompt(
                textPtBR: "Fim de semana. O que foi bem? O que você mudaria?",
                textEn: "End of the week. What went well? What would you change?",
                category: .reflection,
                contextTrigger: PromptTrigger(type: .sunday)
            ),

            // Reflection - Many overdue tasks
            JournalPrompt(
                textPtBR: "Você tem várias coisas pendentes. O que está tornando difícil avançar?",
                textEn: "You have several pending things. What's making it hard to move forward?",
                category: .reflection,
                contextTrigger: PromptTrigger(type: .overdueTasks)
            ),

            // Celebration - Streak milestone
            JournalPrompt(
                textPtBR: "Você está em um streak incrível. O que mudou desde que começou?",
                textEn: "You're on an amazing streak. What has changed since you started?",
                category: .celebration,
                contextTrigger: PromptTrigger(type: .streakMilestone)
            ),
        ]
    }
}
