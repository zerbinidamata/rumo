import Foundation
import AuthenticationServices
import CryptoKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Coordinates Sign in with Apple authentication flow.
/// Handles ASAuthorizationController delegation and nonce generation.
/// Supports both iOS and macOS platforms.
@MainActor
final class AppleSignInCoordinator: NSObject, ObservableObject {

    // MARK: - Published State

    @Published private(set) var isSigningIn: Bool = false
    @Published private(set) var error: AuthError?

    // MARK: - Private State

    private var currentNonce: String?
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    // MARK: - Public Methods

    /// Initiates Sign in with Apple flow
    func signIn() async throws -> ASAuthorizationAppleIDCredential {
        isSigningIn = true
        error = nil

        defer { isSigningIn = false }

        // Generate nonce for security
        let nonce = generateNonce()
        currentNonce = nonce

        // Create request
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        // Create controller
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        // Get presentation anchor (platform-specific)
        guard let anchor = getPresentationAnchor() else {
            throw AuthError.unknown(NSError(domain: "AppleSignIn", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Could not find presentation anchor"
            ]))
        }

        let contextProvider = SignInPresentationContextProvider(anchor: anchor)
        controller.presentationContextProvider = contextProvider

        // Perform request and wait for result
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    /// Checks if the user's Apple ID credential is still valid
    func checkCredentialState(userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    // MARK: - Platform-Specific Anchor

    private func getPresentationAnchor() -> ASPresentationAnchor? {
        #if os(iOS)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        #elseif os(macOS)
        return NSApplication.shared.keyWindow
        #endif
    }

    // MARK: - Nonce Generation

    /// Generates a random nonce for Sign in with Apple
    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)

        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { charset[Int($0) % charset.count] }
        return String(nonce)
    }

    /// SHA256 hash of the nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                continuation?.resume(throwing: AuthError.invalidCredential)
                continuation = nil
                return
            }

            continuation?.resume(returning: credential)
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            let authError: AuthError

            if let asError = error as? ASAuthorizationError {
                switch asError.code {
                case .canceled:
                    authError = .unknown(asError)
                case .invalidResponse:
                    authError = .invalidCredential
                case .notHandled:
                    authError = .unknown(asError)
                case .failed:
                    authError = .networkError
                case .notInteractive:
                    authError = .unknown(asError)
                @unknown default:
                    authError = .unknown(asError)
                }
            } else {
                authError = .unknown(error)
            }

            self.error = authError
            continuation?.resume(throwing: authError)
            continuation = nil
        }
    }
}

// MARK: - Presentation Context Provider

private final class SignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        anchor
    }
}

// MARK: - Credential Extension

extension ASAuthorizationAppleIDCredential {
    /// The nonce used for this credential (stored separately)
    var nonce: String? {
        get { objc_getAssociatedObject(self, &nonceKey) as? String }
        set { objc_setAssociatedObject(self, &nonceKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

private var nonceKey: UInt8 = 0
