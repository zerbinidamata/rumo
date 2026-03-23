import Foundation
import SwiftUI
import AuthenticationServices

/// ViewModel for authentication screens
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published State

    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var error: AuthError?
    @Published var showMagicLinkSent: Bool = false
    @Published var showError: Bool = false

    // MARK: - Dependencies

    private let authRepository: AuthRepository
    private let appleSignIn: AppleSignInCoordinator

    // MARK: - Initialization

    init(
        authRepository: AuthRepository = .shared,
        appleSignIn: AppleSignInCoordinator = AppleSignInCoordinator()
    ) {
        self.authRepository = authRepository
        self.appleSignIn = appleSignIn
    }

    // MARK: - Computed Properties

    var isEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    var canSubmitEmail: Bool {
        isEmailValid && !isLoading
    }

    // MARK: - Actions

    /// Signs in with Apple
    func signInWithApple() async {
        isLoading = true
        error = nil

        do {
            let credential = try await appleSignIn.signIn()
            _ = try await authRepository.signInWithApple(credential: credential)
            // Auth state will be updated by repository
        } catch let authError as AuthError {
            self.error = authError
            self.showError = true
        } catch {
            self.error = .unknown(error)
            self.showError = true
        }

        isLoading = false
    }

    /// Sends a magic link to the entered email
    func sendMagicLink() async {
        guard canSubmitEmail else { return }

        isLoading = true
        error = nil

        do {
            try await authRepository.sendMagicLink(to: email)
            showMagicLinkSent = true
        } catch let authError as AuthError {
            self.error = authError
            self.showError = true
        } catch {
            self.error = .unknown(error)
            self.showError = true
        }

        isLoading = false
    }

    /// Handles a magic link callback URL
    func handleMagicLinkCallback(url: URL) async {
        isLoading = true
        error = nil

        do {
            _ = try await authRepository.verifyMagicLink(url: url)
            // Auth state will be updated by repository
        } catch let authError as AuthError {
            self.error = authError
            self.showError = true
        } catch {
            self.error = .unknown(error)
            self.showError = true
        }

        isLoading = false
    }

    /// Clears the error state
    func clearError() {
        error = nil
        showError = false
    }

    /// Resets the magic link sent state
    func resetMagicLinkSent() {
        showMagicLinkSent = false
        email = ""
    }
}
