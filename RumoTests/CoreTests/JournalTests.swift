import Testing
import Foundation
@testable import Rumo

/// Tests for Journal models
struct JournalEntryTests {

    // MARK: - Initialization Tests

    @Test("JournalEntry initializes correctly")
    func testInitialization() {
        let entry = JournalEntry(
            date: Date(),
            bodyEncrypted: Data("encrypted".utf8),
            bodyHash: "abc123",
            mood: .good,
            wordCount: 150
        )

        #expect(entry.mood == .good)
        #expect(entry.wordCount == 150)
        #expect(!entry.bodyEncrypted.isEmpty)
        #expect(entry.bodyHash == "abc123")
    }

    @Test("JournalEntry date is normalized")
    func testDateNormalization() {
        let afternoonDate = Calendar.current.date(
            bySettingHour: 15,
            minute: 30,
            second: 0,
            of: Date()
        )!

        let entry = JournalEntry(
            date: afternoonDate,
            bodyEncrypted: Data(),
            bodyHash: ""
        )

        let calendar = Calendar.current
        #expect(calendar.component(.hour, from: entry.date) == 0)
    }

    // MARK: - Computed Properties

    @Test("hasLocation returns correct value")
    func testHasLocation() {
        var entry = JournalEntry(
            date: Date(),
            bodyEncrypted: Data(),
            bodyHash: ""
        )
        #expect(entry.hasLocation == false)

        entry.locationLat = 37.7749
        entry.locationLon = -122.4194
        #expect(entry.hasLocation == true)
    }

    @Test("hasPhotos returns correct value")
    func testHasPhotos() {
        var entry = JournalEntry(
            date: Date(),
            bodyEncrypted: Data(),
            bodyHash: ""
        )
        #expect(entry.hasPhotos == false)

        entry.photoIds = ["photo1", "photo2"]
        #expect(entry.hasPhotos == true)
    }

    @Test("hasBeenAnalyzed returns correct value")
    func testHasBeenAnalyzed() {
        var entry = JournalEntry(
            date: Date(),
            bodyEncrypted: Data(),
            bodyHash: ""
        )
        #expect(entry.hasBeenAnalyzed == false)

        entry.sentimentScore = 0.5
        #expect(entry.hasBeenAnalyzed == true)
    }
}

// MARK: - MoodLevel Tests

struct MoodLevelTests {

    @Test("MoodLevel has correct raw values")
    func testRawValues() {
        #expect(MoodLevel.awful.rawValue == 1)
        #expect(MoodLevel.bad.rawValue == 2)
        #expect(MoodLevel.neutral.rawValue == 3)
        #expect(MoodLevel.good.rawValue == 4)
        #expect(MoodLevel.great.rawValue == 5)
    }

    @Test("MoodLevel has emojis")
    func testEmojis() {
        #expect(MoodLevel.awful.emoji == "😢")
        #expect(MoodLevel.great.emoji == "😄")
    }

    @Test("MoodLevel has colors")
    func testColors() {
        for mood in MoodLevel.allCases {
            #expect(mood.color.hasPrefix("#"))
            #expect(mood.color.count == 7)
        }
    }
}

// MARK: - JournalPrompt Tests

struct JournalPromptTests {

    @Test("JournalPrompt initializes correctly")
    func testInitialization() {
        let prompt = JournalPrompt(
            textPtBR: "Como você está se sentindo?",
            textEn: "How are you feeling?",
            category: .reflection
        )

        #expect(prompt.textPtBR == "Como você está se sentindo?")
        #expect(prompt.textEn == "How are you feeling?")
        #expect(prompt.category == .reflection)
        #expect(prompt.isActive == true)
    }

    @Test("Default prompts are created")
    func testDefaultPrompts() {
        let prompts = JournalPrompt.createDefaultPrompts()

        #expect(!prompts.isEmpty)
        #expect(prompts.count >= 9) // At least 9 default prompts

        // Check variety of categories
        let categories = Set(prompts.map { $0.category })
        #expect(categories.contains(.gratitude))
        #expect(categories.contains(.reflection))
        #expect(categories.contains(.celebration))
    }
}

// MARK: - PromptCategory Tests

struct PromptCategoryTests {

    @Test("PromptCategory has display names")
    func testDisplayNames() {
        for category in PromptCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("PromptCategory has icons")
    func testIcons() {
        for category in PromptCategory.allCases {
            #expect(!category.icon.isEmpty)
        }
    }
}
