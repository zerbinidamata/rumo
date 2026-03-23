import Testing
import Foundation
@testable import Rumo

/// Tests for Date extensions
struct DateExtensionTests {

    // MARK: - Start/End of Day Tests

    @Test("startOfDay returns midnight")
    func testStartOfDay() {
        let date = Calendar.current.date(
            bySettingHour: 15,
            minute: 30,
            second: 45,
            of: Date()
        )!

        let start = date.startOfDay
        let calendar = Calendar.current

        #expect(calendar.component(.hour, from: start) == 0)
        #expect(calendar.component(.minute, from: start) == 0)
        #expect(calendar.component(.second, from: start) == 0)
    }

    @Test("endOfDay returns 23:59:59")
    func testEndOfDay() {
        let date = Calendar.current.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: Date()
        )!

        let end = date.endOfDay
        let calendar = Calendar.current

        #expect(calendar.component(.hour, from: end) == 23)
        #expect(calendar.component(.minute, from: end) == 59)
        #expect(calendar.component(.second, from: end) == 59)
    }

    // MARK: - Date Comparison Tests

    @Test("isToday returns correct value")
    func testIsToday() {
        let today = Date()
        #expect(today.isToday == true)

        let yesterday = today.addingTimeInterval(-86400)
        #expect(yesterday.isToday == false)

        let tomorrow = today.addingTimeInterval(86400)
        #expect(tomorrow.isToday == false)
    }

    @Test("isYesterday returns correct value")
    func testIsYesterday() {
        let today = Date()
        let yesterday = today.addingTimeInterval(-86400)

        #expect(today.isYesterday == false)
        #expect(yesterday.isYesterday == true)
    }

    @Test("isTomorrow returns correct value")
    func testIsTomorrow() {
        let today = Date()
        let tomorrow = today.addingTimeInterval(86400)

        #expect(today.isTomorrow == false)
        #expect(tomorrow.isTomorrow == true)
    }

    @Test("isPast returns correct value")
    func testIsPast() {
        let yesterday = Date().addingTimeInterval(-86400)
        #expect(yesterday.isPast == true)

        let tomorrow = Date().addingTimeInterval(86400)
        #expect(tomorrow.isPast == false)
    }

    @Test("isFuture returns correct value")
    func testIsFuture() {
        let tomorrow = Date().addingTimeInterval(86400)
        #expect(tomorrow.isFuture == true)

        let yesterday = Date().addingTimeInterval(-86400)
        #expect(yesterday.isFuture == false)
    }

    // MARK: - Day of Week Tests

    @Test("isWeekend returns correct value")
    func testIsWeekend() {
        let calendar = Calendar.current

        // Create a known Saturday
        let saturday = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 21
        ))!
        #expect(saturday.isWeekend == true)

        // Create a known Monday
        let monday = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 23
        ))!
        #expect(monday.isWeekend == false)
    }

    @Test("isMonday returns correct value")
    func testIsMonday() {
        let calendar = Calendar.current
        let monday = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 23
        ))!

        #expect(monday.isMonday == true)
        #expect(monday.isSunday == false)
    }

    @Test("isSunday returns correct value")
    func testIsSunday() {
        let calendar = Calendar.current
        let sunday = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 22
        ))!

        #expect(sunday.isSunday == true)
        #expect(sunday.isMonday == false)
    }

    // MARK: - Date Arithmetic Tests

    @Test("adding days")
    func testAddingDays() {
        let today = Date().startOfDay
        let tomorrow = today.adding(days: 1)
        let nextWeek = today.adding(days: 7)

        #expect(today.days(to: tomorrow) == 1)
        #expect(today.days(to: nextWeek) == 7)
    }

    @Test("subtracting days")
    func testSubtractingDays() {
        let today = Date().startOfDay
        let yesterday = today.subtracting(days: 1)
        let lastWeek = today.subtracting(days: 7)

        #expect(yesterday.days(to: today) == 1)
        #expect(lastWeek.days(to: today) == 7)
    }

    // MARK: - Date Range Tests

    @Test("ClosedRange dates property")
    func testDateRangeDates() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 1
        ))!
        let end = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 5
        ))!

        let range = start...end
        let dates = range.dates

        #expect(dates.count == 5)
        #expect(dates.first == start.startOfDay)
        #expect(dates.last == end.startOfDay)
    }
}
