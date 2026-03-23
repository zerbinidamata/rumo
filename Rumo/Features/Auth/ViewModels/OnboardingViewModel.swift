import Foundation
import SwiftUI
import UserNotifications

/// Steps in the onboarding flow
enum OnboardingStep: Int, CaseIterable {
    case welcome
    case pillars
    case notifications
    case complete

    var title: LocalizedStringKey {
        switch self {
        case .welcome: return "onboarding.welcome.title"
        case .pillars: return "onboarding.pillars.title"
        case .notifications: return "onboarding.notifications.title"
        case .complete: return "onboarding.complete.title"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .welcome: return "onboarding.welcome.subtitle"
        case .pillars: return "onboarding.pillars.subtitle"
        case .notifications: return "onboarding.notifications.subtitle"
        case .complete: return "onboarding.complete.subtitle"
        }
    }
}

/// ViewModel managing onboarding flow state and logic
@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedPillars: Set<Pilar> = []
    @Published var notificationsEnabled: Bool = false
    @Published var isComplete: Bool = false

    // MARK: - Computed Properties

    var progress: CGFloat {
        CGFloat(currentStep.rawValue + 1) / CGFloat(OnboardingStep.allCases.count)
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .pillars:
            return !selectedPillars.isEmpty
        case .notifications:
            return true
        case .complete:
            return true
        }
    }

    // MARK: - Navigation

    func nextStep() {
        guard let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              nextIndex + 1 < OnboardingStep.allCases.count else {
            completeOnboarding()
            return
        }

        currentStep = OnboardingStep.allCases[nextIndex + 1]

        if currentStep == .complete {
            // Save selections before showing complete screen
            saveOnboardingSelections()
        }
    }

    func previousStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }

        currentStep = OnboardingStep.allCases[currentIndex - 1]
    }

    // MARK: - Pillar Selection

    func togglePillar(_ pillar: Pilar) {
        if selectedPillars.contains(pillar) {
            selectedPillars.remove(pillar)
        } else {
            selectedPillars.insert(pillar)
        }
    }

    // MARK: - Notifications

    func requestNotifications() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            notificationsEnabled = granted

            if granted {
                // Save notification preference
                await ProfileManager.shared.updatePreferences(notificationsEnabled: true)
            }
        } catch {
            print("Notification permission error: \(error)")
            notificationsEnabled = false
        }
    }

    // MARK: - Private Methods

    private func saveOnboardingSelections() {
        // Save selected pillars to user defaults for quick access
        let pillarStrings = selectedPillars.map { $0.rawValue }
        UserDefaults.standard.set(pillarStrings, forKey: "selectedPillars")

        // Update profile preferences
        Task {
            await ProfileManager.shared.updatePreferences(
                notificationsEnabled: notificationsEnabled
            )
        }
    }

    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Dismiss the onboarding view
        isComplete = true
    }
}
