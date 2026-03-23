import SwiftUI

/// Onboarding flow after successful authentication
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            progressBar
                .padding(.top, 8)

            // Content
            TabView(selection: $viewModel.currentStep) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    stepView(for: step)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)

            // Navigation Buttons
            navigationButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                dismiss()
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 4)

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * viewModel.progress, height: 4)
                    .animation(.easeInOut, value: viewModel.progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
    }

    // MARK: - Step Views

    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            welcomeStep
        case .pillars:
            pillarsStep
        case .notifications:
            notificationsStep
        case .complete:
            completeStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            Image(systemName: "arrow.up.right.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(.tint)

            VStack(spacing: 16) {
                Text(viewModel.currentStep.title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(viewModel.currentStep.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Features
            VStack(alignment: .leading, spacing: 16) {
                featureRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "onboarding.feature.tasks"
                )
                featureRow(
                    icon: "flame.fill",
                    color: .orange,
                    title: "onboarding.feature.habits"
                )
                featureRow(
                    icon: "book.fill",
                    color: .blue,
                    title: "onboarding.feature.journal"
                )
                featureRow(
                    icon: "brain.head.profile",
                    color: .purple,
                    title: "onboarding.feature.insights"
                )
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var pillarsStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text(viewModel.currentStep.title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(viewModel.currentStep.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Pillar Selection
            VStack(spacing: 16) {
                pillarCard(
                    pillar: .tasks,
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "onboarding.pillar.tasks.title",
                    description: "onboarding.pillar.tasks.description"
                )

                pillarCard(
                    pillar: .habits,
                    icon: "flame.fill",
                    color: .orange,
                    title: "onboarding.pillar.habits.title",
                    description: "onboarding.pillar.habits.description"
                )

                pillarCard(
                    pillar: .journal,
                    icon: "book.fill",
                    color: .blue,
                    title: "onboarding.pillar.journal.title",
                    description: "onboarding.pillar.journal.description"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var notificationsStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 100))
                .foregroundStyle(.tint)

            VStack(spacing: 16) {
                Text(viewModel.currentStep.title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(viewModel.currentStep.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Benefits
            VStack(alignment: .leading, spacing: 16) {
                benefitRow(icon: "clock.fill", text: "onboarding.notification.benefit.1")
                benefitRow(icon: "flame.fill", text: "onboarding.notification.benefit.2")
                benefitRow(icon: "lightbulb.fill", text: "onboarding.notification.benefit.3")
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var completeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Celebration
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 120))
                .foregroundStyle(.green)

            VStack(spacing: 16) {
                Text(viewModel.currentStep.title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(viewModel.currentStep.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Summary
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.selectedPillars.isEmpty {
                    Text("onboarding.complete.pillars")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack {
                        ForEach(Array(viewModel.selectedPillars), id: \.self) { pillar in
                            pillarBadge(pillar)
                        }
                    }
                }

                Divider()

                HStack {
                    Image(systemName: viewModel.notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                        .foregroundStyle(viewModel.notificationsEnabled ? .green : .secondary)

                    Text(viewModel.notificationsEnabled
                         ? "onboarding.complete.notifications.on"
                         : "onboarding.complete.notifications.off")
                        .font(.subheadline)
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep != .welcome {
                Button {
                    viewModel.previousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 50, height: 50)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }

            Button {
                if viewModel.currentStep == .notifications && !viewModel.notificationsEnabled {
                    Task {
                        await viewModel.requestNotifications()
                        viewModel.nextStep()
                    }
                } else {
                    viewModel.nextStep()
                }
            } label: {
                Text(buttonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.canProceed ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canProceed)
        }
    }

    private var buttonTitle: LocalizedStringKey {
        switch viewModel.currentStep {
        case .welcome:
            return "onboarding.button.start"
        case .pillars:
            return "onboarding.button.continue"
        case .notifications:
            return "onboarding.button.enable"
        case .complete:
            return "onboarding.button.finish"
        }
    }

    // MARK: - Helper Views

    private func featureRow(icon: String, color: Color, title: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            Text(title)
                .font(.body)
        }
    }

    private func pillarCard(
        pillar: Pilar,
        icon: String,
        color: Color,
        title: LocalizedStringKey,
        description: LocalizedStringKey
    ) -> some View {
        let isSelected = viewModel.selectedPillars.contains(pillar)

        return Button {
            viewModel.togglePillar(pillar)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? color : Color(.systemGray4))
            }
            .padding(16)
            .background(isSelected ? color.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func benefitRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func pillarBadge(_ pillar: Pilar) -> some View {
        let (icon, color): (String, Color) = {
            switch pillar {
            case .tasks: return ("checkmark.circle.fill", .green)
            case .habits: return ("flame.fill", .orange)
            case .journal: return ("book.fill", .blue)
            case .crossPillar: return ("brain.head.profile", .purple)
            }
        }()

        return HStack(spacing: 4) {
            Image(systemName: icon)
            Text(pillar.rawValue.capitalized)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
