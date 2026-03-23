import Testing
import Foundation
@testable import Rumo

/// Tests for Habit model
struct HabitTests {

    // MARK: - Initialization Tests

    @Test("Habit initializes with default values")
    func testDefaultInitialization() {
        let habit = Habit(name: "Meditation")

        #expect(habit.name == "Meditation")
        #expect(habit.emoji == "✨")
        #expect(habit.color == "#007AFF")
        #expect(habit.type == .good)
        #expect(habit.goalValue == 1)
        #expect(habit.goalUnit == "vez")
        #expect(habit.frequency.type == .daily)
        #expect(habit.reminderTime == nil)
        #expect(habit.categoryId == nil)
        #expect(habit.archivedAt == nil)
    }

    @Test("Habit initializes with custom values")
    func testCustomInitialization() {
        let habit = Habit(
            name: "Drink Water",
            emoji: "💧",
            color: "#00BFFF",
            type: .good,
            goalValue: 8,
            goalUnit: "cups",
            frequency: .weekdays
        )

        #expect(habit.name == "Drink Water")
        #expect(habit.emoji == "💧")
        #expect(habit.goalValue == 8)
        #expect(habit.goalUnit == "cups")
        #expect(habit.frequency.daysOfWeek == [1, 2, 3, 4, 5])
    }

    // MARK: - Computed Properties Tests

    @Test("isArchived returns correct value")
    func testIsArchived() {
        let activeHabit = Habit(name: "Active")
        #expect(activeHabit.isArchived == false)

        var archivedHabit = Habit(name: "Archived")
        archivedHabit.archivedAt = Date()
        #expect(archivedHabit.isArchived == true)
    }

    @Test("isBinary returns correct value")
    func testIsBinary() {
        let binaryHabit = Habit(name: "Binary", goalValue: 1)
        #expect(binaryHabit.isBinary == true)

        let quantitativeHabit = Habit(name: "Quantitative", goalValue: 8)
        #expect(quantitativeHabit.isBinary == false)
    }

    @Test("isScheduled returns correct value for daily habit")
    func testIsScheduledDaily() {
        let habit = Habit(
            name: "Daily",
            frequency: .daily
        )

        let today = Date()
        let tomorrow = today.addingTimeInterval(86400)

        #expect(habit.isScheduled(for: today) == true)
        #expect(habit.isScheduled(for: tomorrow) == true)
    }

    @Test("isScheduled returns correct value for weekly habit")
    func testIsScheduledWeekly() {
        let habit = Habit(
            name: "Mon-Wed-Fri",
            frequency: HabitFrequency(
                type: .weekly,
                daysOfWeek: [1, 3, 5] // Monday, Wednesday, Friday
            )
        )

        // Create dates for each day of the week
        let calendar = Calendar.current
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 22))!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 23))!
        let tuesday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 24))!
        let wednesday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 25))!

        #expect(habit.isScheduled(for: sunday) == false)
        #expect(habit.isScheduled(for: monday) == true)
        #expect(habit.isScheduled(for: tuesday) == false)
        #expect(habit.isScheduled(for: wednesday) == true)
    }
}

// MARK: - HabitLog Tests

struct HabitLogTests {

    @Test("HabitLog initializes correctly")
    func testInitialization() {
        let habitId = UUID()
        let log = HabitLog(
            habitId: habitId,
            date: Date(),
            value: 5,
            status: .completed,
            note: "Great day!"
        )

        #expect(log.habitId == habitId)
        #expect(log.value == 5)
        #expect(log.status == .completed)
        #expect(log.note == "Great day!")
    }

    @Test("HabitLog date is normalized to start of day")
    func testDateNormalization() {
        let habitId = UUID()
        let afternoonDate = Calendar.current.date(
            bySettingHour: 15,
            minute: 30,
            second: 0,
            of: Date()
        )!

        let log = HabitLog(habitId: habitId, date: afternoonDate)

        let calendar = Calendar.current
        #expect(calendar.component(.hour, from: log.date) == 0)
        #expect(calendar.component(.minute, from: log.date) == 0)
    }
}

// MARK: - HabitFrequency Tests

struct HabitFrequencyTests {

    @Test("Daily frequency")
    func testDaily() {
        let freq = HabitFrequency.daily

        #expect(freq.type == .daily)
        #expect(freq.daysOfWeek == nil)
    }

    @Test("Weekdays frequency")
    func testWeekdays() {
        let freq = HabitFrequency.weekdays

        #expect(freq.type == .weekly)
        #expect(freq.daysOfWeek == [1, 2, 3, 4, 5])
    }

    @Test("Custom frequency")
    func testCustom() {
        let freq = HabitFrequency(
            type: .monthly,
            daysOfMonth: [1, 15]
        )

        #expect(freq.type == .monthly)
        #expect(freq.daysOfMonth == [1, 15])
    }
}

// MARK: - Achievement Tests

struct AchievementTests {

    @Test("Achievement types have correct properties")
    func testAchievementTypes() {
        for type in AchievementType.allCases {
            #expect(!type.displayName.isEmpty)
            #expect(!type.description.isEmpty)
            #expect(!type.icon.isEmpty)
            #expect(type.xpReward > 0)
        }
    }

    @Test("Achievement XP rewards are correct")
    func testXPRewards() {
        #expect(AchievementType.firstStep.xpReward == 50)
        #expect(AchievementType.perfectWeek.xpReward == 100)
        #expect(AchievementType.centurion.xpReward == 1000)
    }

    @Test("Achievement pillars are correct")
    func testPilars() {
        #expect(AchievementType.perfectWeek.pilar == .habits)
        #expect(AchievementType.writer.pilar == .journal)
        #expect(AchievementType.totalFocus.pilar == .tasks)
        #expect(AchievementType.tripleDay.pilar == .crossPillar)
    }
}
