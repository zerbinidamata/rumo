import Foundation
import NaturalLanguage

/// Parses natural language input to extract task details
struct QuickAddParser {

    // MARK: - Parsed Result

    struct ParsedTask {
        var title: String
        var dueDate: Date?
        var priority: TaskPriority
        var tags: [String]
        var listName: String?
    }

    // MARK: - Parsing

    /// Parses a natural language string into task components
    /// Examples:
    /// - "Buy groceries tomorrow !high #shopping"
    /// - "Call mom today at 3pm"
    /// - "Finish report by Friday !medium"
    /// - "Meeting with team next Monday at 10am #work"
    static func parse(_ input: String) -> ParsedTask {
        var remainingText = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var priority: TaskPriority = .none
        var tags: [String] = []
        var listName: String?
        var dueDate: Date?

        // Extract priority flags (!high, !medium, !low, !!)
        (remainingText, priority) = extractPriority(from: remainingText)

        // Extract tags (#tag)
        (remainingText, tags) = extractTags(from: remainingText)

        // Extract list (@list)
        (remainingText, listName) = extractList(from: remainingText)

        // Extract date/time using NaturalLanguage
        (remainingText, dueDate) = extractDate(from: remainingText)

        // Clean up title
        let title = remainingText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")

        return ParsedTask(
            title: title.isEmpty ? input : title,
            dueDate: dueDate,
            priority: priority,
            tags: tags,
            listName: listName
        )
    }

    // MARK: - Priority Extraction

    private static func extractPriority(from text: String) -> (String, TaskPriority) {
        var result = text
        var priority: TaskPriority = .none

        // Check for !! (high priority shorthand)
        if result.contains("!!") {
            priority = .high
            result = result.replacingOccurrences(of: "!!", with: "")
        }

        // Check for explicit priority flags
        let priorityPatterns: [(String, TaskPriority)] = [
            ("!high", .high),
            ("!alta", .high),
            ("!medium", .medium),
            ("!media", .medium),
            ("!média", .medium),
            ("!low", .low),
            ("!baixa", .low),
            ("!p1", .high),
            ("!p2", .medium),
            ("!p3", .low)
        ]

        for (pattern, p) in priorityPatterns {
            if result.lowercased().contains(pattern) {
                priority = p
                result = result.replacingOccurrences(
                    of: pattern,
                    with: "",
                    options: .caseInsensitive
                )
                break
            }
        }

        return (result, priority)
    }

    // MARK: - Tag Extraction

    private static func extractTags(from text: String) -> (String, [String]) {
        var result = text
        var tags: [String] = []

        let tagPattern = #"#(\w+)"#
        let regex = try? NSRegularExpression(pattern: tagPattern)
        let range = NSRange(result.startIndex..., in: result)

        if let matches = regex?.matches(in: result, range: range) {
            for match in matches.reversed() {
                if let tagRange = Range(match.range(at: 1), in: result) {
                    tags.insert(String(result[tagRange]), at: 0)
                }
                if let fullRange = Range(match.range, in: result) {
                    result.removeSubrange(fullRange)
                }
            }
        }

        return (result, tags)
    }

    // MARK: - List Extraction

    private static func extractList(from text: String) -> (String, String?) {
        var result = text
        var listName: String?

        let listPattern = #"@(\w+)"#
        let regex = try? NSRegularExpression(pattern: listPattern)
        let range = NSRange(result.startIndex..., in: result)

        if let match = regex?.firstMatch(in: result, range: range) {
            if let listRange = Range(match.range(at: 1), in: result) {
                listName = String(result[listRange])
            }
            if let fullRange = Range(match.range, in: result) {
                result.removeSubrange(fullRange)
            }
        }

        return (result, listName)
    }

    // MARK: - Date Extraction

    private static func extractDate(from text: String) -> (String, Date?) {
        var result = text
        var extractedDate: Date?

        let calendar = Calendar.current
        let now = Date()

        // Common date keywords (English and Portuguese)
        let dateKeywords: [(String, () -> Date?)] = [
            // English
            ("today", { now }),
            ("tonight", { calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) }),
            ("tomorrow", { calendar.date(byAdding: .day, value: 1, to: now) }),
            ("next week", { calendar.date(byAdding: .weekOfYear, value: 1, to: now) }),
            ("next month", { calendar.date(byAdding: .month, value: 1, to: now) }),
            ("this weekend", { nextWeekend() }),

            // Portuguese
            ("hoje", { now }),
            ("amanhã", { calendar.date(byAdding: .day, value: 1, to: now) }),
            ("amanha", { calendar.date(byAdding: .day, value: 1, to: now) }),
            ("próxima semana", { calendar.date(byAdding: .weekOfYear, value: 1, to: now) }),
            ("proxima semana", { calendar.date(byAdding: .weekOfYear, value: 1, to: now) }),
            ("fim de semana", { nextWeekend() })
        ]

        // Check for keyword matches
        for (keyword, dateGenerator) in dateKeywords {
            if result.lowercased().contains(keyword) {
                extractedDate = dateGenerator()
                result = result.replacingOccurrences(
                    of: keyword,
                    with: "",
                    options: .caseInsensitive
                )
                break
            }
        }

        // Check for day names
        let dayNames = [
            ("monday", "segunda", 2),
            ("tuesday", "terça", 3),
            ("wednesday", "quarta", 4),
            ("thursday", "quinta", 5),
            ("friday", "sexta", 6),
            ("saturday", "sábado", 7),
            ("sunday", "domingo", 1)
        ]

        for (english, portuguese, weekday) in dayNames {
            if result.lowercased().contains(english) || result.lowercased().contains(portuguese) {
                extractedDate = nextDate(for: weekday)
                result = result.replacingOccurrences(of: english, with: "", options: .caseInsensitive)
                result = result.replacingOccurrences(of: portuguese, with: "", options: .caseInsensitive)
                break
            }
        }

        // Try to extract time (e.g., "at 3pm", "às 15h")
        if extractedDate != nil {
            let timePatterns = [
                #"at\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#,
                #"às?\s*(\d{1,2})(?::(\d{2}))?(?:\s*h(?:oras?)?)?"#
            ]

            for pattern in timePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   let match = regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) {

                    var hour = 0
                    var minute = 0

                    if let hourRange = Range(match.range(at: 1), in: result) {
                        hour = Int(result[hourRange]) ?? 0
                    }

                    if match.numberOfRanges > 2,
                       let minuteRange = Range(match.range(at: 2), in: result),
                       !result[minuteRange].isEmpty {
                        minute = Int(result[minuteRange]) ?? 0
                    }

                    // Handle AM/PM
                    if match.numberOfRanges > 3,
                       let ampmRange = Range(match.range(at: 3), in: result) {
                        let ampm = result[ampmRange].lowercased()
                        if ampm == "pm" && hour < 12 {
                            hour += 12
                        } else if ampm == "am" && hour == 12 {
                            hour = 0
                        }
                    }

                    extractedDate = calendar.date(
                        bySettingHour: hour,
                        minute: minute,
                        second: 0,
                        of: extractedDate!
                    )

                    if let fullRange = Range(match.range, in: result) {
                        result.removeSubrange(fullRange)
                    }
                    break
                }
            }
        }

        // Use NSDataDetector as fallback
        if extractedDate == nil {
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let range = NSRange(result.startIndex..., in: result)

            if let match = detector?.firstMatch(in: result, range: range),
               let date = match.date {
                extractedDate = date

                if let matchRange = Range(match.range, in: result) {
                    result.removeSubrange(matchRange)
                }
            }
        }

        // Remove common prepositions left over
        let prepositions = ["by", "on", "at", "para", "até", "em", "no", "na"]
        for prep in prepositions {
            result = result.replacingOccurrences(
                of: " \(prep) ",
                with: " ",
                options: .caseInsensitive
            )
            // Also handle at start/end
            if result.lowercased().hasPrefix("\(prep) ") {
                result = String(result.dropFirst(prep.count + 1))
            }
            if result.lowercased().hasSuffix(" \(prep)") {
                result = String(result.dropLast(prep.count + 1))
            }
        }

        return (result, extractedDate)
    }

    // MARK: - Helper Methods

    private static func nextWeekend() -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = 7 // Saturday
        return calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        )
    }

    private static func nextDate(for weekday: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = weekday
        return calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        )
    }
}
