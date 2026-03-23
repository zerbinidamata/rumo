import SwiftData
import Foundation

// MARK: - Mood Level

enum MoodLevel: Int, Codable, CaseIterable, Sendable {
    case awful = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case great = 5

    var displayName: String {
        switch self {
        case .awful: return String(localized: "mood.awful")
        case .bad: return String(localized: "mood.bad")
        case .neutral: return String(localized: "mood.neutral")
        case .good: return String(localized: "mood.good")
        case .great: return String(localized: "mood.great")
        }
    }

    var emoji: String {
        switch self {
        case .awful: return "😢"
        case .bad: return "😔"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .great: return "😄"
        }
    }

    var color: String {
        switch self {
        case .awful: return "#FF3B30"
        case .bad: return "#FF9500"
        case .neutral: return "#8E8E93"
        case .good: return "#34C759"
        case .great: return "#007AFF"
        }
    }
}

// MARK: - Journal Entry Model

@Model
final class JournalEntry: Sendable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var bodyEncrypted: Data
    var bodyHash: String
    var mood: MoodLevel?
    var photoIds: [String]
    var audioUrl: String?
    var locationLat: Double?
    var locationLon: Double?
    var tags: [String]
    var promptId: UUID?
    var wordCount: Int
    var sentimentScore: Float?
    var topics: [String]
    var embedding: [Float]?
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        date: Date,
        bodyEncrypted: Data,
        bodyHash: String,
        mood: MoodLevel? = nil,
        photoIds: [String] = [],
        audioUrl: String? = nil,
        locationLat: Double? = nil,
        locationLon: Double? = nil,
        tags: [String] = [],
        promptId: UUID? = nil,
        wordCount: Int = 0,
        sentimentScore: Float? = nil,
        topics: [String] = []
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.bodyEncrypted = bodyEncrypted
        self.bodyHash = bodyHash
        self.mood = mood
        self.photoIds = photoIds
        self.audioUrl = audioUrl
        self.locationLat = locationLat
        self.locationLon = locationLon
        self.tags = tags
        self.promptId = promptId
        self.wordCount = wordCount
        self.sentimentScore = sentimentScore
        self.topics = topics
        self.embedding = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
    }
}

// MARK: - Computed Properties

extension JournalEntry {

    var hasLocation: Bool {
        locationLat != nil && locationLon != nil
    }

    var hasPhotos: Bool {
        !photoIds.isEmpty
    }

    var hasAudio: Bool {
        audioUrl != nil
    }

    /// Whether sentiment analysis has been performed
    var hasBeenAnalyzed: Bool {
        sentimentScore != nil
    }
}

// MARK: - Syncable Conformance

extension JournalEntry: Syncable {
    static var tableName: String { "journal_entries" }
}
