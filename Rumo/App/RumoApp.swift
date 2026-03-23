import SwiftUI
import SwiftData

/// Main entry point for the Rumo app.
/// Configures the app environment, SwiftData container, and root coordinator.
/// Supports both iOS and macOS platforms.
@main
struct RumoApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    #endif

    @StateObject private var appCoordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer

    init() {
        // Initialize SwiftData container with shared App Group for widget access
        do {
            modelContainer = try ModelContainer.shared
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appCoordinator)
                .environment(\.locale, appCoordinator.currentLocale)
                .onOpenURL { url in
                    appCoordinator.handle(url: url)
                }
                .fullScreenCover(isPresented: $appCoordinator.showOnboarding) {
                    OnboardingView()
                }
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        #endif
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                appCoordinator.handleAppBecameActive()
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appCoordinator)
        }
        #endif
    }
}

// MARK: - Root View

/// Root view that handles navigation based on auth state
struct RootView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        Group {
            switch coordinator.authState {
            case .unknown:
                LaunchScreenView()
            case .unauthenticated:
                AuthCoordinatorView()
            case .authenticated:
                MainNavigationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.authState)
    }
}

// MARK: - Launch Screen

/// Placeholder launch screen shown during initial auth check
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)

                Text("Rumo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
        }
    }
}

// MARK: - Main Navigation (Platform Adaptive)

/// Adaptive navigation: TabView on iOS, Sidebar on macOS
struct MainNavigationView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        #if os(iOS)
        TabNavigationView()
        #elseif os(macOS)
        SidebarNavigationView()
        #endif
    }
}

// MARK: - iOS Tab Navigation

#if os(iOS)
struct TabNavigationView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            DashboardPlaceholderView()
                .tabItem {
                    Label("dashboard.tab", systemImage: "house.fill")
                }
                .tag(AppCoordinator.Tab.dashboard)

            TaskListView()
                .tabItem {
                    Label("tasks.tab", systemImage: "checkmark.circle.fill")
                }
                .tag(AppCoordinator.Tab.tasks)

            HabitsPlaceholderView()
                .tabItem {
                    Label("habits.tab", systemImage: "flame.fill")
                }
                .tag(AppCoordinator.Tab.habits)

            JournalPlaceholderView()
                .tabItem {
                    Label("journal.tab", systemImage: "book.fill")
                }
                .tag(AppCoordinator.Tab.journal)

            SettingsPlaceholderView()
                .tabItem {
                    Label("settings.tab", systemImage: "gearshape.fill")
                }
                .tag(AppCoordinator.Tab.settings)
        }
    }
}
#endif

// MARK: - macOS Sidebar Navigation

#if os(macOS)
struct SidebarNavigationView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        NavigationSplitView {
            List(selection: $coordinator.selectedTab) {
                Section("navigation.main") {
                    Label("dashboard.tab", systemImage: "house.fill")
                        .tag(AppCoordinator.Tab.dashboard)

                    Label("tasks.tab", systemImage: "checkmark.circle.fill")
                        .tag(AppCoordinator.Tab.tasks)

                    Label("habits.tab", systemImage: "flame.fill")
                        .tag(AppCoordinator.Tab.habits)

                    Label("journal.tab", systemImage: "book.fill")
                        .tag(AppCoordinator.Tab.journal)
                }

                Section("navigation.other") {
                    Label("settings.tab", systemImage: "gearshape.fill")
                        .tag(AppCoordinator.Tab.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            switch coordinator.selectedTab {
            case .dashboard:
                DashboardPlaceholderView()
            case .tasks:
                TaskListView()
            case .habits:
                HabitsPlaceholderView()
            case .journal:
                JournalPlaceholderView()
            case .settings:
                SettingsPlaceholderView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

/// macOS Settings View (shown in Settings window)
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("settings.general", systemImage: "gearshape")
                }

            AccountSettingsView()
                .tabItem {
                    Label("settings.account", systemImage: "person.circle")
                }

            NotificationSettingsView()
                .tabItem {
                    Label("settings.notifications", systemImage: "bell")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Text("settings.general.placeholder")
        }
        .padding()
    }
}

struct AccountSettingsView: View {
    var body: some View {
        Form {
            Text("settings.account.placeholder")
        }
        .padding()
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Form {
            Text("settings.notifications.placeholder")
        }
        .padding()
    }
}
#endif

// MARK: - Placeholder Views for Other Tabs

struct DashboardPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("dashboard.coming")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("dashboard.tab")
        }
    }
}

struct HabitsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                Text("habits.coming")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("habits.tab")
        }
    }
}

struct JournalPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("journal.coming")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("journal.tab")
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("settings.coming")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("settings.tab")
        }
    }
}
