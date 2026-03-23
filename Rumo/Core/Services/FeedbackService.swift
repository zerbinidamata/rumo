import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Cross-platform feedback service for haptics and sounds
/// Provides haptic feedback on iOS, audio/visual feedback on macOS
@MainActor
final class FeedbackService {

    // MARK: - Singleton

    static let shared = FeedbackService()

    private init() {}

    // MARK: - Feedback Types

    enum FeedbackType {
        case success
        case warning
        case error
        case light
        case medium
        case heavy
        case selection
    }

    // MARK: - Public Methods

    /// Triggers appropriate feedback for the platform
    func trigger(_ type: FeedbackType) {
        #if os(iOS)
        triggerIOSFeedback(type)
        #elseif os(macOS)
        triggerMacOSFeedback(type)
        #endif
    }

    /// Triggers feedback for task completion
    func taskCompleted() {
        trigger(.success)
    }

    /// Triggers feedback for habit completion
    func habitCompleted() {
        trigger(.success)
    }

    /// Triggers feedback for level up
    func levelUp() {
        trigger(.success)
        // Could also play a sound here
    }

    /// Triggers feedback for selection change
    func selectionChanged() {
        trigger(.selection)
    }

    /// Triggers feedback for errors
    func errorOccurred() {
        trigger(.error)
    }

    // MARK: - iOS Implementation

    #if os(iOS)
    private func triggerIOSFeedback(_ type: FeedbackType) {
        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)

        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()

        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
    #endif

    // MARK: - macOS Implementation

    #if os(macOS)
    private func triggerMacOSFeedback(_ type: FeedbackType) {
        switch type {
        case .success:
            NSSound.beep()
            // Or use a custom success sound
            // NSSound(named: "Glass")?.play()

        case .warning:
            NSSound.beep()

        case .error:
            NSSound.beep()

        case .light, .medium, .heavy:
            // No haptics on Mac, could flash window or similar
            break

        case .selection:
            // No haptics on Mac
            break
        }
    }
    #endif
}

// MARK: - Convenience Extensions

extension FeedbackService {

    /// Triggers feedback with animation completion
    func triggerWithAnimation(_ type: FeedbackType, animation: @escaping () -> Void) {
        trigger(type)
        animation()
    }
}
