import Foundation

extension Date {

    // MARK: - Start of Day

    /// Returns the start of the day (00:00:00) for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns the end of the day (23:59:59) for this date
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }

    // MARK: - Date Comparisons

    /// Whether this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Whether this date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Whether this date is in the past (before today)
    var isPast: Bool {
        self < Date().startOfDay
    }

    /// Whether this date is in the future (after today)
    var isFuture: Bool {
        self > Date().endOfDay
    }

    /// Whether this date is in the same week as today
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    // MARK: - Day of Week

    /// Returns the day of week (0 = Sunday, 6 = Saturday)
    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: self) - 1
    }

    /// Whether this date is a weekend (Saturday or Sunday)
    var isWeekend: Bool {
        Calendar.current.isDateInWeekend(self)
    }

    /// Whether this date is Monday
    var isMonday: Bool {
        dayOfWeek == 1
    }

    /// Whether this date is Sunday
    var isSunday: Bool {
        dayOfWeek == 0
    }

    // MARK: - Date Arithmetic

    /// Adds the specified number of days to this date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    /// Subtracts the specified number of days from this date
    func subtracting(days: Int) -> Date {
        adding(days: -days)
    }

    /// Returns the number of days between this date and another date
    func days(to other: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startOfDay, to: other.startOfDay)
        return components.day ?? 0
    }

    // MARK: - Formatting

    /// Returns a relative date string (today, yesterday, tomorrow, or formatted date)
    func relativeString(style: Date.RelativeFormatStyle.Presentation = .named) -> String {
        self.formatted(.relative(presentation: style))
    }

    /// Returns the date formatted for display (e.g., "15 de março")
    func displayString(includeYear: Bool = false) -> String {
        let format: Date.FormatStyle = includeYear
            ? .dateTime.day().month(.wide).year()
            : .dateTime.day().month(.wide)
        return formatted(format)
    }

    /// Returns just the time (e.g., "14:30")
    func timeString() -> String {
        formatted(.dateTime.hour().minute())
    }
}

// MARK: - Date Range

extension ClosedRange where Bound == Date {

    /// Returns all dates in this range
    var dates: [Date] {
        var dates: [Date] = []
        var current = lowerBound.startOfDay

        while current <= upperBound.startOfDay {
            dates.append(current)
            current = current.adding(days: 1)
        }

        return dates
    }
}
