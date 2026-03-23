import Foundation
import AuthenticationServices

/// Authentication state for the app
enum AuthState: Equatable, Sendable {
    case unknown
    case unauthenticated
    case authenticated(User)

    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }

    var user: User? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}

/// User model for the app
struct User: Equatable, Sendable, Codable {
    let id: String
    let email: String?
    let displayName: String?
    let avatarURL: String?
    let createdAt: Date

    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        avatarURL: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}

/// Protocol defining authentication operations
protocol AuthRepositoryProtocol: Sendable {
    /// Signs in with Apple credential
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User

    /// Sends a magic link to the provided email
    func sendMagicLink(to email: String) async throws

    /// Verifies a magic link callback URL
    func verifyMagicLink(url: URL) async throws -> User

    /// Signs out the current user
    func signOut() async throws

    /// Deletes the current user's account
    func deleteAccount() async throws

    /// Gets the current user if authenticated
    var currentUser: User? { get async }

    /// Stream of auth state changes
    var authStateStream: AsyncStream<AuthState> { get }
}

/// Implementation of AuthRepository using Supabase
@MainActor
final class AuthRepository: ObservableObject, AuthRepositoryProtocol {

    // MARK: - Singleton

    static let shared = AuthRepository()

    // MARK: - Published State

    @Published private(set) var authState: AuthState = .unknown

    // MARK: - Dependencies

    private let supabase: SupabaseManager
    private let keychain: KeychainManager

    // MARK: - State

    private var authStateContinuation: AsyncStream<AuthState>.Continuation?

    // MARK: - Initialization

    private init(
        supabase: SupabaseManager = .shared,
        keychain: KeychainManager = .shared
    ) {
        self.supabase = supabase
        self.keychain = keychain

        setupAuthStateObserver()
    }

    // MARK: - Auth State Stream

    var authStateStream: AsyncStream<AuthState> {
        AsyncStream { continuation in
            self.authStateContinuation = continuation

            // Send current state immediately
            continuation.yield(self.authState)

            continuation.onTermination = { @Sendable _ in
                // Cleanup if needed
            }
        }
    }

    // MARK: - Current User

    var currentUser: User? {
        get async {
            authState.user
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        // Generate nonce for security
        let nonce = credential.nonce ?? ""

        // Sign in with Supabase
        let supabaseUser = try await supabase.signInWithApple(
            idToken: idTokenString,
            nonce: nonce
        )

        // Create local user
        let user = User(
            id: supabaseUser.id.uuidString,
            email: supabaseUser.email,
            displayName: credential.fullName?.formatted(),
            createdAt: supabaseUser.createdAt
        )

        // Save user ID to keychain
        try? keychain.set(user.id, for: KeychainManager.userIdKey)

        // Create or update user profile
        await createUserProfileIfNeeded(for: user)

        // Update state
        authState = .authenticated(user)
        authStateContinuation?.yield(authState)

        return user
    }

    // MARK: - Magic Link

    func sendMagicLink(to email: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        try await supabase.sendMagicLink(to: email)
    }

    func verifyMagicLink(url: URL) async throws -> User {
        let supabaseUser = try await supabase.verifyMagicLink(url: url)

        let user = User(
            id: supabaseUser.id.uuidString,
            email: supabaseUser.email,
            createdAt: supabaseUser.createdAt
        )

        // Save user ID to keychain
        try? keychain.set(user.id, for: KeychainManager.userIdKey)

        // Create or update user profile
        await createUserProfileIfNeeded(for: user)

        // Update state
        authState = .authenticated(user)
        authStateContinuation?.yield(authState)

        return user
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.signOut()

        // Clear keychain
        try? keychain.delete(for: KeychainManager.userIdKey)

        // Update state
        authState = .unauthenticated
        authStateContinuation?.yield(authState)
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        try await supabase.deleteAccount()

        // Clear all keychain data
        try? keychain.deleteAll()

        // Note: Local SwiftData is preserved but disassociated
        // User can sign in again to start fresh

        // Update state
        authState = .unauthenticated
        authStateContinuation?.yield(authState)
    }

    // MARK: - Session Check

    /// Checks for existing session on app launch
    func checkExistingSession() async {
        do {
            try await supabase.refreshSessionIfNeeded()

            if supabase.isAuthenticated, let supabaseUser = supabase.currentUser {
                let user = User(
                    id: supabaseUser.id.uuidString,
                    email: supabaseUser.email,
                    createdAt: supabaseUser.createdAt
                )
                authState = .authenticated(user)
            } else {
                authState = .unauthenticated
            }
        } catch {
            authState = .unauthenticated
        }

        authStateContinuation?.yield(authState)
    }

    // MARK: - Private Methods

    private func setupAuthStateObserver() {
        Task {
            await checkExistingSession()
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func createUserProfileIfNeeded(for user: User) async {
        // Will create UserProfile in SwiftData if it doesn't exist
        // Implementation in Phase 3 completion
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case invalidCredential
    case invalidEmail
    case sessionExpired
    case networkError
    case accountDeleted
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return String(localized: "error.auth.invalidCredential")
        case .invalidEmail:
            return String(localized: "error.auth.invalidEmail")
        case .sessionExpired:
            return String(localized: "error.auth.sessionExpired")
        case .networkError:
            return String(localized: "error.auth.networkError")
        case .accountDeleted:
            return String(localized: "error.auth.accountDeleted")
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
