import SwiftUI
import AuthenticationServices

/// Main login screen with Sign in with Apple and magic link options
struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Logo and Welcome
                    headerSection
                        .padding(.top, geometry.size.height * 0.1)

                    Spacer(minLength: 40)

                    // Auth Options
                    authOptionsSection

                    Spacer(minLength: 20)

                    // Footer
                    footerSection
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.keyboard)
        .alert(
            "error.title",
            isPresented: $viewModel.showError,
            presenting: viewModel.error
        ) { _ in
            Button("common.ok", role: .cancel) {
                viewModel.clearError()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $viewModel.showMagicLinkSent) {
            MagicLinkSentView(
                email: viewModel.email,
                onDismiss: { viewModel.resetMagicLinkSent() }
            )
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(systemName: "arrow.up.right.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            // App Name
            Text("Rumo")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Tagline
            Text("login.tagline")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Auth Options Section

    private var authOptionsSection: some View {
        VStack(spacing: 16) {
            // Sign in with Apple
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.email, .fullName]
                },
                onCompletion: { _ in }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)
            .disabled(viewModel.isLoading)
            .overlay {
                // Custom tap handler for our flow
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await viewModel.signInWithApple()
                        }
                    }
            }

            // Divider
            HStack {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)

                Text("login.or")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)

            // Email Input
            VStack(alignment: .leading, spacing: 8) {
                TextField("login.email.placeholder", text: $viewModel.email)
                    .textFieldStyle(.plain)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isEmailFocused)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isEmailFocused ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )

                if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                    Text("login.email.invalid")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Magic Link Button
            Button {
                isEmailFocused = false
                Task {
                    await viewModel.sendMagicLink()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("login.magicLink.button")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canSubmitEmail ? Color.accentColor : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSubmitEmail)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("login.terms.prefix")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Link("login.terms.link", destination: URL(string: "https://rumo.app/terms")!)
                Text("login.terms.and")
                Link("login.privacy.link", destination: URL(string: "https://rumo.app/privacy")!)
            }
            .font(.caption)
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Magic Link Sent View

struct MagicLinkSentView: View {
    let email: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            // Title
            Text("magicLink.sent.title")
                .font(.title2)
                .fontWeight(.semibold)

            // Message
            Text("magicLink.sent.message \(email)")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: 1, text: "magicLink.instruction.1")
                instructionRow(number: 2, text: "magicLink.instruction.2")
                instructionRow(number: 3, text: "magicLink.instruction.3")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)

            Spacer()

            // Dismiss Button
            Button("common.ok") {
                onDismiss()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .padding(24)
    }

    private func instructionRow(number: Int, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
}
