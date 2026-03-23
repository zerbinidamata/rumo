import SwiftUI

/// Coordinates the authentication flow including login and onboarding
struct AuthCoordinatorView: View {
    @StateObject private var authRepository = AuthRepository.shared
    @State private var showOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            LoginView()
                .navigationBarHidden(true)
        }
        .onChange(of: authRepository.authState) { _, newState in
            if case .authenticated = newState {
                // Check if onboarding is needed
                if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                    showOnboarding = true
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onOpenURL { url in
            // Handle magic link callback
            Task {
                let viewModel = AuthViewModel()
                await viewModel.handleMagicLinkCallback(url: url)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AuthCoordinatorView()
}
