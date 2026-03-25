import SwiftUI
import Combine
import UserNotifications

/// Pomodoro timer view for focused work sessions
struct PomodoroTimerView: View {
    let task: TaskItem?
    @ObservedObject var viewModel: PomodoroViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Task info
                if let task = task {
                    VStack(spacing: 8) {
                        Text("pomodoro.workingOn")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(task.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                // Timer Circle
                timerCircle

                // Session info
                sessionInfo

                Spacer()

                // Controls
                controlButtons

                Spacer()
            }
            .padding()
            .navigationTitle("pomodoro.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.showSettings = true
                        } label: {
                            Label("pomodoro.settings", systemImage: "gearshape")
                        }

                        Button {
                            viewModel.reset()
                        } label: {
                            Label("pomodoro.reset", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                PomodoroSettingsView(viewModel: viewModel)
            }
            .alert(
                "pomodoro.sessionComplete",
                isPresented: $viewModel.showCompletionAlert
            ) {
                Button("common.ok") {
                    viewModel.acknowledgeCompletion()
                }
            } message: {
                Text(viewModel.completionMessage)
            }
        }
    }

    // MARK: - Timer Circle

    private var timerCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)
                .frame(width: 280, height: 280)

            // Progress circle
            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    viewModel.currentPhase.color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: viewModel.progress)

            // Time display
            VStack(spacing: 8) {
                Text(viewModel.timeString)
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .monospacedDigit()

                Text(viewModel.currentPhase.localizedName)
                    .font(.headline)
                    .foregroundStyle(viewModel.currentPhase.color)
            }
        }
    }

    // MARK: - Session Info

    private var sessionInfo: some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                Text("\(viewModel.completedPomodoros)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)

                Text("pomodoro.completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(viewModel.totalMinutesWorked)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)

                Text("pomodoro.minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 24) {
            // Skip button
            Button {
                viewModel.skip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, height: 50)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            // Play/Pause button
            Button {
                viewModel.toggleTimer()
            } label: {
                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(viewModel.currentPhase.color)
                    .clipShape(Circle())
                    .shadow(color: viewModel.currentPhase.color.opacity(0.3), radius: 8, y: 4)
            }

            // Stop button
            Button {
                viewModel.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, height: 50)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Pomodoro ViewModel

@MainActor
final class PomodoroViewModel: ObservableObject {

    // MARK: - Published State

    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var currentPhase: PomodoroPhase = .work
    @Published var completedPomodoros: Int = 0
    @Published var showCompletionAlert: Bool = false
    @Published var showSettings: Bool = false

    // MARK: - Settings

    @Published var workDuration: Int = 25
    @Published var shortBreakDuration: Int = 5
    @Published var longBreakDuration: Int = 15
    @Published var pomodorosUntilLongBreak: Int = 4

    // MARK: - Private

    private var timer: AnyCancellable?
    private var sessionStartTime: Date?
    private var backgroundedAt: Date?
    private var sessionTaskTitle: String?

    // MARK: - Session Tracking

    @Published var sessionTaskId: UUID?

    func startSession(for taskId: UUID, title: String?) {
        sessionTaskId = taskId
        sessionTaskTitle = title
    }

    var completionMessage: LocalizedStringKey {
        switch currentPhase {
        case .work:
            return "pomodoro.workComplete"
        case .shortBreak, .longBreak:
            return "pomodoro.breakComplete"
        }
    }

    // MARK: - Computed Properties

    var progress: CGFloat {
        let total = totalSecondsForPhase
        guard total > 0 else { return 0 }
        return CGFloat(total - remainingSeconds) / CGFloat(total)
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var totalMinutesWorked: Int {
        completedPomodoros * workDuration
    }

    private var totalSecondsForPhase: Int {
        switch currentPhase {
        case .work:
            return workDuration * 60
        case .shortBreak:
            return shortBreakDuration * 60
        case .longBreak:
            return longBreakDuration * 60
        }
    }

    // MARK: - Initialization

    init() {
        loadSettings()
        remainingSeconds = workDuration * 60
    }

    // MARK: - Timer Control

    func toggleTimer() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func start() {
        isRunning = true
        sessionStartTime = Date()

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func stop() {
        pause()
        remainingSeconds = totalSecondsForPhase
    }

    func skip() {
        pause()
        transitionToNextPhase()
    }

    func reset() {
        pause()
        currentPhase = .work
        completedPomodoros = 0
        remainingSeconds = workDuration * 60
        sessionTaskId = nil
        sessionTaskTitle = nil
    }

    func acknowledgeCompletion() {
        showCompletionAlert = false
        transitionToNextPhase()
    }

    // MARK: - Private Methods

    private func tick() {
        guard remainingSeconds > 0 else {
            completePhase()
            return
        }
        remainingSeconds -= 1
    }

    private func completePhase() {
        pause()

        if currentPhase == .work {
            completedPomodoros += 1

            // Award XP for completing a pomodoro
            Task {
                await ProfileManager.shared.addXP(25)
            }
        }

        // Play completion sound/haptic
        playCompletionFeedback()

        showCompletionAlert = true
    }

    private func transitionToNextPhase() {
        switch currentPhase {
        case .work:
            if completedPomodoros % pomodorosUntilLongBreak == 0 {
                currentPhase = .longBreak
                remainingSeconds = longBreakDuration * 60
            } else {
                currentPhase = .shortBreak
                remainingSeconds = shortBreakDuration * 60
            }
        case .shortBreak, .longBreak:
            currentPhase = .work
            remainingSeconds = workDuration * 60
        }
    }

    private func playCompletionFeedback() {
        // Cross-platform feedback
        FeedbackService.shared.trigger(.success)
    }

    private func loadSettings() {
        if let profile = ProfileManager.shared.currentProfile {
            workDuration = profile.pomodoroDuration
            shortBreakDuration = profile.shortBreakDuration
            longBreakDuration = profile.longBreakDuration
        }
    }

    // MARK: - Background Handling

    func handleBackground() {
        guard isRunning else { return }
        backgroundedAt = Date()
        scheduleCompletionNotification(in: remainingSeconds, taskTitle: sessionTaskTitle)
    }

    func handleForeground() {
        cancelCompletionNotification()
        guard isRunning, let bg = backgroundedAt else {
            backgroundedAt = nil
            return
        }
        backgroundedAt = nil
        let elapsed = Int(Date().timeIntervalSince(bg))
        if elapsed >= remainingSeconds {
            remainingSeconds = 0
            completePhase()
        } else {
            remainingSeconds -= elapsed
        }
    }

    private func scheduleCompletionNotification(in seconds: Int, taskTitle: String?) {
        let content = UNMutableNotificationContent()
        content.title = currentPhase == .work
            ? String(localized: "pomodoro.notification.workDone")
            : String(localized: "pomodoro.notification.breakDone")
        if let title = taskTitle, currentPhase == .work {
            content.body = title
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, TimeInterval(seconds)),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "pomodoro-completion",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["pomodoro-completion"]
        )
    }

    func saveSettings() {
        Task {
            await ProfileManager.shared.updatePreferences(
                pomodoroDuration: workDuration,
                shortBreakDuration: shortBreakDuration,
                longBreakDuration: longBreakDuration
            )
        }
        remainingSeconds = totalSecondsForPhase
    }
}

// MARK: - Pomodoro Phase

enum PomodoroPhase {
    case work
    case shortBreak
    case longBreak

    var localizedName: LocalizedStringKey {
        switch self {
        case .work: return "pomodoro.phase.work"
        case .shortBreak: return "pomodoro.phase.shortBreak"
        case .longBreak: return "pomodoro.phase.longBreak"
        }
    }

    var color: Color {
        switch self {
        case .work: return .orange
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}

// MARK: - Pomodoro Settings View

struct PomodoroSettingsView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(
                        "pomodoro.settings.work \(viewModel.workDuration)",
                        value: $viewModel.workDuration,
                        in: 1...60
                    )

                    Stepper(
                        "pomodoro.settings.shortBreak \(viewModel.shortBreakDuration)",
                        value: $viewModel.shortBreakDuration,
                        in: 1...30
                    )

                    Stepper(
                        "pomodoro.settings.longBreak \(viewModel.longBreakDuration)",
                        value: $viewModel.longBreakDuration,
                        in: 1...60
                    )
                } header: {
                    Text("pomodoro.settings.durations")
                }

                Section {
                    Stepper(
                        "pomodoro.settings.longBreakInterval \(viewModel.pomodorosUntilLongBreak)",
                        value: $viewModel.pomodorosUntilLongBreak,
                        in: 2...8
                    )
                } header: {
                    Text("pomodoro.settings.intervals")
                }
            }
            .navigationTitle("pomodoro.settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PomodoroTimerView(task: TaskItem(title: "Sample Task", priority: .high), viewModel: PomodoroViewModel())
}
