import SwiftUI

extension Color {

    // MARK: - Hex Initialization

    /// Creates a Color from a hex string (e.g., "#FF0000" or "FF0000")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Hex String

    /// Returns the hex string representation of this color
    var hexString: String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }

    // MARK: - App Colors

    /// Primary accent color
    static let rumoAccent = Color("AccentColor")

    /// Success color (green)
    static let rumoSuccess = Color(hex: "#34C759")

    /// Warning color (orange)
    static let rumoWarning = Color(hex: "#FF9500")

    /// Error color (red)
    static let rumoError = Color(hex: "#FF3B30")

    /// Neutral color (gray)
    static let rumoNeutral = Color(hex: "#8E8E93")

    // MARK: - Mood Colors

    static func mood(_ level: MoodLevel) -> Color {
        Color(hex: level.color)
    }

    // MARK: - Priority Colors

    static func priority(_ level: TaskPriority) -> Color {
        Color(hex: level.color)
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {

    /// Creates a gradient from a single color (darker to lighter)
    init(color: Color) {
        self.init(
            colors: [color.opacity(0.8), color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
