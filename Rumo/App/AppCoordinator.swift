import SwiftUI
import Combine

/// Root coordinator that manages app-wide state and navigation.
/// Follows MVVM + Coordinator pattern as specified in PRD.
@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Published State

    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var currentLocale: Locale = .current
    @Published private(set) var currentUser: User?
    @Published var selectedTab: Tab = .dashboard
    @Published var showOnboarding: Bool = false

    // MARK: - Dependencies

    private let authRepository: AuthRepository
    private let syncManager: SyncManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Tab Definition

    enum Tab: Int, CaseIterable, Identifiable {
        case dashboard
        case tasks
        case habits
        case journal
        case settings

        var id: Int { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .dashboard: return "dashboard.tab"
            case .tasks: return "tasks.tab"
            case .habits: return "habits.tab"
            case .journal: return "journal.tab"
            case .settings: return "settings.tab"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .tasks: return "checkmark.circle.fill"
            case .habits: return "flame.fill"
            case .journal: return "book.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    // MARK: - Initialization

    init(
        authRepository: AuthRepository = .shared,
        syncManager: SyncManager = .shared
    ) {
        self.authRepository = authRepository
        self.syncManager = syncManager

        setupLocale()
        setupAuthStateObserver()
    }

    // MARK: - Public Methods

    /// Updates the app locale based on user preference
    func setLocale(_ locale: Locale) {
        currentLocale = locale
        UserDefaults.standard.set(locale.identifier, forKey: "app_locale")
        UserDefaults.standard.set([locale.identifier], forKey: "AppleLanguages")
    }

    /// Signs the user out
    func signOut() async {
        do {
            try await authRepository.signOut()
            // Stop sync
            await syncManager.stop()
        } catch {
            print("Sign out error: \(error)")
        }
    }

    /// Navigates to a specific tab
    func navigate(to tab: Tab) {
        selectedTab = tab
    }

    /// Handles app becoming active
    func handleAppBecameActive() {
        Task {
            // Check for credential revocation (Apple Sign In)
            await checkCredentialValidity()

            // Resume sync if authenticated
            if authState.isAuthenticated {
                await syncManager.performFullSync()
            }
        }
    }

    // MARK: - Private Methods

    private func setupLocale() {
        if let savedLocale = UserDefaults.standard.string(forKey: "app_locale") {
            currentLocale = Locale(identifier: savedLocale)
        } else {
            let preferred = Locale.current
            if preferred.language.languageCode?.identifier == "pt" {
                currentLocale = Locale(identifier: "pt-BR")
            } else {
                currentLocale = Locale(identifier: "en")
            }
        }
    }

    private func setupAuthStateObserver() {
        #if DEBUG
        if Config.bypassAuth {
            let fakeUser = User(id: "debug-user", email: "dev@rumo.app", displayName: "Dev User")
            handleAuthStateChange(.authenticated(fakeUser))
            return
        }
        #endif

        // Observe auth state changes from repository
        authRepository.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.handleAuthStateChange(newState)
            }
            .store(in: &cancellables)

        // Initial auth check
        Task {
            await authRepository.checkExistingSession()
        }
    }

    private func handleAuthStateChange(_ newState: AuthState) {
        authState = newState

        switch newState {
        case .unknown:
            break

        case .unauthenticated:
            currentUser = nil
            // Reset to default tab when signed out
            selectedTab = .dashboard

        case .authenticated(let user):
            currentUser = user

            // Check if onboarding is needed
            if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                showOnboarding = true
            }

            // Start sync service
            Task {
                await syncManager.start()
            }
        }
    }

    private func checkCredentialValidity() async {
        guard let userId = currentUser?.id else { return }

        let coordinator = AppleSignInCoordinator()
        let state = await coordinator.checkCredentialState(userID: userId)

        if state == .revoked || state == .notFound {
            // Credential revoked, sign out
            await signOut()
        }
    }
}

// MARK: - Deep Link Handling

extension AppCoordinator {

    /// Handles incoming deep links and universal links
    func handle(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        // Check if it's a Supabase auth callback
        if url.absoluteString.contains("auth/callback") ||
           url.absoluteString.contains("access_token") {
            handleAuthDeepLink(url)
            return
        }

        switch components.host {
        case "auth":
            handleAuthDeepLink(url)
        case "task":
            handleTaskDeepLink(components)
        case "habit":
            handleHabitDeepLink(components)
        case "journal":
            handleJournalDeepLink(components)
        default:
            break
        }
    }

    private func handleAuthDeepLink(_ url: URL) {
        // Handle magic link callback
        Task {
            do {
                _ = try await authRepository.verifyMagicLink(url: url)
            } catch {
                print("Magic link verification failed: \(error)")
            }
        }
    }

    private func handleTaskDeepLink(_ components: URLComponents) {
        navigate(to: .tasks)

        // Parse task ID from path
        if let taskId = components.queryItems?.first(where: { $0.name == "id" })?.value {
            // Post notification to navigate to task detail
            NotificationCenter.default.post(
                name: .navigateToTask,
                object: nil,
                userInfo: ["taskId": taskId]
            )
        }
    }

    private func handleHabitDeepLink(_ components: URLComponents) {
        navigate(to: .habits)

        if let habitId = components.queryItems?.first(where: { $0.name == "id" })?.value {
            NotificationCenter.default.post(
                name: .navigateToHabit,
                object: nil,
                userInfo: ["habitId": habitId]
            )
        }
    }

    private func handleJournalDeepLink(_ components: URLComponents) {
        navigate(to: .journal)

        if let dateString = components.queryItems?.first(where: { $0.name == "date" })?.value {
            NotificationCenter.default.post(
                name: .navigateToJournalEntry,
                object: nil,
                userInfo: ["date": dateString]
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToTask = Notification.Name("navigateToTask")
    static let navigateToHabit = Notification.Name("navigateToHabit")
    static let navigateToJournalEntry = Notification.Name("navigateToJournalEntry")
}
