import Foundation
import LocalAuthentication

/// Service for biometric authentication (Face ID / Touch ID).
/// Used to protect the journal module when enabled.
@MainActor
final class BiometricAuth: ObservableObject {

    // MARK: - Singleton

    static let shared = BiometricAuth()

    // MARK: - Published State

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var biometryType: BiometryType = .none
    @Published private(set) var isAvailable: Bool = false

    // MARK: - Types

    enum BiometryType: String {
        case none
        case touchID
        case faceID
        case opticID

        var displayName: String {
            switch self {
            case .none: return String(localized: "biometry.none")
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }

        var icon: String {
            switch self {
            case .none: return "lock.fill"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .opticID: return "opticid"
            }
        }
    }

    // MARK: - Private Properties

    private let context: LAContext

    // MARK: - Initialization

    private init() {
        context = LAContext()
        checkAvailability()
    }

    // MARK: - Public Methods

    /// Checks if biometric authentication is available
    func checkAvailability() {
        var error: NSError?
        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .none:
            biometryType = .none
        case .touchID:
            biometryType = .touchID
        case .faceID:
            biometryType = .faceID
        case .opticID:
            biometryType = .opticID
        @unknown default:
            biometryType = .none
        }
    }

    /// Authenticates the user with biometrics
    /// - Parameter reason: The reason shown to the user
    /// - Returns: True if authentication succeeded
    func authenticate(reason: String? = nil) async -> Bool {
        guard isAvailable else { return false }

        let localizedReason = reason ?? String(localized: "biometry.reason.journal")

        // Create a fresh context for each authentication
        let authContext = LAContext()
        authContext.localizedCancelTitle = String(localized: "common.cancel")
        authContext.localizedFallbackTitle = String(localized: "biometry.fallback")

        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: localizedReason
            )
            isAuthenticated = success
            return success
        } catch {
            isAuthenticated = false
            return false
        }
    }

    /// Authenticates with biometrics, falling back to device passcode
    /// - Parameter reason: The reason shown to the user
    /// - Returns: True if authentication succeeded
    func authenticateWithPasscodeFallback(reason: String? = nil) async -> Bool {
        let localizedReason = reason ?? String(localized: "biometry.reason.journal")

        let authContext = LAContext()

        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: localizedReason
            )
            isAuthenticated = success
            return success
        } catch {
            isAuthenticated = false
            return false
        }
    }

    /// Resets the authentication state (e.g., when app goes to background)
    func resetAuthentication() {
        isAuthenticated = false
    }

    /// Invalidates the current context (forces re-authentication)
    func invalidate() {
        context.invalidate()
        isAuthenticated = false
    }
}

// MARK: - Biometric Error

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case passcodeNotSet
    case systemCancelled
    case unknown(Error)

    init(from laError: LAError) {
        switch laError.code {
        case .biometryNotAvailable:
            self = .notAvailable
        case .biometryNotEnrolled:
            self = .notEnrolled
        case .authenticationFailed:
            self = .authenticationFailed
        case .userCancel:
            self = .userCancelled
        case .passcodeNotSet:
            self = .passcodeNotSet
        case .systemCancel:
            self = .systemCancelled
        default:
            self = .unknown(laError)
        }
    }

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return String(localized: "error.biometric.notAvailable")
        case .notEnrolled:
            return String(localized: "error.biometric.notEnrolled")
        case .authenticationFailed:
            return String(localized: "error.biometric.failed")
        case .userCancelled:
            return String(localized: "error.biometric.cancelled")
        case .passcodeNotSet:
            return String(localized: "error.biometric.noPasscode")
        case .systemCancelled:
            return String(localized: "error.biometric.systemCancelled")
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
