import SwiftUI
import SwiftData

/// Main view displaying the list of tasks with filtering and sorting
struct TaskListView: View {
    @StateObject private var viewModel = TasksViewModel()
    @StateObject private var pomodoroVM = PomodoroViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showQuickAdd: Bool = false
    @State private var quickAddText: String = ""
    @State private var showSortMenu: Bool = false
    @State private var showFilterMenu: Bool = false
    @State private var showListPicker: Bool = false
    @State private var showCreateList: Bool = false
    @State private var showMatrix: Bool = false
    @State private var showConfetti: Bool = false
    @State private var confettiKey: UUID = UUID()
    @State private var pomodoroTask: TaskItem? = nil
    @State private var showPomodoroSheet: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Filter Pills
                    filterPills
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    // Task List or Matrix
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
                    } else if showMatrix {
                        EisenhowerMatrixView(tasks: viewModel.tasks) { task in
                            viewModel.selectTask(task)
                        } onToggle: { task in
                            if !task.isCompleted { triggerConfetti() }
                            Task { await viewModel.toggleTaskCompletion(task) }
                        }
                    } else if viewModel.tasks.isEmpty {
                        emptyState
                    } else {
                        taskList
                    }
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }

                // Completion confetti
                if showConfetti {
                    ConfettiBurst { showConfetti = false }
                        .id(confettiKey)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle(navigationTitle)
            .searchable(text: $viewModel.searchText, prompt: "tasks.search")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    listMenuButton
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            showMatrix.toggle()
                        } label: {
                            Image(systemName: showMatrix ? "list.bullet" : "square.grid.2x2")
                        }
                        sortMenuButton
                    }
                }
            }
            .sheet(isPresented: $showQuickAdd) {
                QuickAddSheet(
                    text: $quickAddText,
                    onSubmit: { parsed, selectedDate in
                        Task {
                            await viewModel.createTask(
                                title: parsed.title,
                                dueDate: selectedDate ?? parsed.dueDate,
                                priority: parsed.priority,
                                tagNames: parsed.tags
                            )
                        }
                        showQuickAdd = false
                        quickAddText = ""
                    },
                    onCancel: {
                        showQuickAdd = false
                        quickAddText = ""
                    }
                )
                .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $viewModel.showTaskEditor) {
                TaskEditorView(
                    task: viewModel.editingTask,
                    lists: viewModel.lists,
                    availableTags: viewModel.tags,
                    onSave: { task, list, tags in
                        Task {
                            if viewModel.editingTask != nil {
                                await viewModel.updateTask(task)
                            } else {
                                await viewModel.createTask(
                                    title: task.title,
                                    notes: task.notes,
                                    dueDate: task.dueDate,
                                    priority: task.priority,
                                    list: list,
                                    tagNames: tags.map { $0.name }
                                )
                            }
                            viewModel.showTaskEditor = false
                        }
                    },
                    onCancel: {
                        viewModel.showTaskEditor = false
                    },
                    onCreateList: { name, color, icon in
                        await viewModel.createListAndReturn(name: name, color: color, icon: icon)
                    }
                )
            }
            .sheet(isPresented: $viewModel.showTaskDetail) {
                if let task = viewModel.selectedTask {
                    TaskDetailView(
                        task: task,
                        onEdit: {
                            viewModel.showTaskDetail = false
                            viewModel.editTask(task)
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteTask(task)
                            }
                            viewModel.showTaskDetail = false
                        },
                        onToggleComplete: {
                            Task {
                                await viewModel.toggleTaskCompletion(task)
                            }
                        }
                    )
                }
            }
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
        }
        .sheet(isPresented: $showCreateList) {
            CreateListSheet { name, color, icon in
                Task {
                    await viewModel.createList(name: name, color: color, icon: icon)
                }
                showCreateList = false
            } onCancel: {
                showCreateList = false
            }
        }
        .sheet(isPresented: $showPomodoroSheet) {
            if let task = pomodoroTask {
                PomodoroTimerView(task: task, viewModel: pomodoroVM)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: pomodoroVM.handleBackground()
            case .active:     pomodoroVM.handleForeground()
            default:          break
            }
        }
        .task {
            await viewModel.loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTask)) { notification in
            if let taskId = notification.userInfo?["taskId"] as? String {
                // Find and select the task
                if let task = viewModel.tasks.first(where: { $0.id.uuidString == taskId }) {
                    viewModel.selectTask(task)
                }
            }
        }
    }

    // MARK: - Confetti

    private func triggerConfetti() {
        confettiKey = UUID()
        showConfetti = true
    }

    private func startPomodoro(for task: TaskItem) {
        if pomodoroVM.sessionTaskId != task.id {
            pomodoroVM.reset()
            pomodoroVM.startSession(for: task.id, title: task.title)
        }
        pomodoroTask = task
        showPomodoroSheet = true
    }

    // MARK: - Navigation Title

    private var navigationTitle: LocalizedStringKey {
        if let list = viewModel.selectedList {
            return LocalizedStringKey(list.name)
        }
        return viewModel.filterOption.localizedName
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TasksViewModel.FilterOption.allCases) { filter in
                    FilterPill(
                        title: filter.localizedName,
                        isSelected: viewModel.filterOption == filter,
                        count: countFor(filter: filter)
                    ) {
                        viewModel.setFilter(filter)
                    }
                }
            }
        }
    }

    private func countFor(filter: TasksViewModel.FilterOption) -> Int? {
        switch filter {
        case .all:
            return nil
        case .today:
            return viewModel.todayTasks.count
        case .upcoming:
            return viewModel.upcomingTasks.count
        case .overdue:
            return viewModel.overdueTasks.count
        case .completed:
            return viewModel.completedTasks.count
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            ForEach(viewModel.tasks) { task in
                TaskRowView(
                    task: task,
                    onToggle: {
                        Task { await viewModel.toggleTaskCompletion(task) }
                    },
                    onComplete: triggerConfetti,
                    onStartPomodoro: { startPomodoro(for: task) },
                    isInProgress: task.id == pomodoroVM.sessionTaskId
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectTask(task)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteTask(task)
                        }
                    } label: {
                        Label("common.delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Task {
                            await viewModel.toggleTaskCompletion(task)
                        }
                    } label: {
                        Label(
                            task.isCompleted ? "tasks.uncomplete" : "tasks.complete",
                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                        )
                    }
                    .tint(.green)
                }
            }
            .onDelete { offsets in
                Task {
                    await viewModel.deleteTasks(at: offsets)
                }
            }
            .onMove { source, destination in
                Task {
                    await viewModel.reorderTasks(from: source, to: destination)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("tasks.empty.title")
                .font(.title3)
                .fontWeight(.semibold)

            Text("tasks.empty.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Menu {
                Button { viewModel.createNewTask() } label: {
                    Label("tasks.add.full", systemImage: "square.and.pencil")
                }
                Button { showQuickAdd = true } label: {
                    Label("tasks.add.quick", systemImage: "bolt")
                }
            } label: {
                Label("tasks.add", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Menu {
            Button {
                viewModel.createNewTask()
            } label: {
                Label("tasks.add.full", systemImage: "square.and.pencil")
            }
            Button {
                showQuickAdd = true
            } label: {
                Label("tasks.add.quick", systemImage: "bolt")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }

    // MARK: - Toolbar Buttons

    private var listMenuButton: some View {
        Menu {
            Button {
                showCreateList = true
            } label: {
                Label("lists.new", systemImage: "plus")
            }

            Divider()

            Button {
                viewModel.selectList(nil)
            } label: {
                HStack {
                    Text("tasks.allLists")
                    if viewModel.selectedList == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(viewModel.lists) { list in
                Button {
                    viewModel.selectList(list)
                } label: {
                    HStack {
                        Image(systemName: list.icon)
                            .foregroundStyle(Color(hex: list.color))
                        Text(list.name)
                        if viewModel.selectedList?.id == list.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }

    private var sortMenuButton: some View {
        Menu {
            ForEach(TasksViewModel.SortOption.allCases) { option in
                Button {
                    viewModel.setSort(option)
                } label: {
                    HStack {
                        Text(option.localizedName)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    var onComplete: (() -> Void)? = nil
    var onStartPomodoro: (() -> Void)? = nil
    var isInProgress: Bool = false

    @State private var checkScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: handleToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : priorityColor)
                    .scaleEffect(checkScale)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    // In Progress badge
                    if isInProgress {
                        InProgressBadge()
                    }

                    // Due date
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.caption)
                        .foregroundStyle(dueDateColor(dueDate))
                    }

                    // Tags
                    if let tags = task.tags, !tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(tags.prefix(2)) { tag in
                                Text("#\(tag.name)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: tag.color).opacity(0.2))
                                    .foregroundStyle(Color(hex: tag.color))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            Spacer()

            // Pomodoro button
            if !task.isCompleted {
                Button {
                    onStartPomodoro?()
                } label: {
                    Image(systemName: "timer")
                        .font(.callout)
                        .foregroundStyle(isInProgress ? .orange : .secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            // Priority indicator
            if task.priority != .none {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }

    private func handleToggle() {
        if !task.isCompleted {
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { checkScale = 1.5 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.55)) { checkScale = 1.0 }
            }
            onComplete?()
        } else {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
        onToggle()
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        case .none: return .secondary
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        if task.isCompleted { return .secondary }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return .orange
        } else if date < Date() {
            return .red
        } else if calendar.isDateInTomorrow(date) {
            return .blue
        }
        return .secondary
    }
}

// MARK: - In Progress Badge

private struct InProgressBadge: View {
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.orange)
                .frame(width: 6, height: 6)
                .scaleEffect(pulsing ? 1.4 : 0.7)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)
            Text("tasks.inProgress")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
        }
        .onAppear { pulsing = true }
    }
}

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    @Binding var text: String
    let onSubmit: (QuickAddParser.ParsedTask, Date?) -> Void
    let onCancel: () -> Void

    @State private var selectedDate: QuickDate = .none
    @State private var customDate: Date = Date()
    @State private var showCustomPicker: Bool = false
    @FocusState private var isFocused: Bool

    enum QuickDate: Equatable {
        case none, today, tomorrow, nextWeek, custom
    }

    private var resolvedDate: Date? {
        let calendar = Calendar.current
        switch selectedDate {
        case .none:       return nil
        case .today:      return calendar.startOfDay(for: Date())
        case .tomorrow:   return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))
        case .nextWeek:   return calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: Date()))
        case .custom:     return customDate
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("tasks.quickAdd.placeholder", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isFocused)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                // Date quick buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickDateButton("tasks.quickAdd.noDate", date: .none, icon: "xmark")
                        quickDateButton("tasks.quickAdd.today", date: .today, icon: "sun.max")
                        quickDateButton("tasks.quickAdd.tomorrow", date: .tomorrow, icon: "sunrise")
                        quickDateButton("tasks.quickAdd.nextWeek", date: .nextWeek, icon: "calendar")
                        quickDateButton("tasks.quickAdd.custom", date: .custom, icon: "calendar.badge.plus")
                    }
                    .padding(.horizontal, 1)
                }

                if showCustomPicker {
                    DatePicker(
                        "",
                        selection: $customDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }

                // Parsed tags preview
                let parsed = QuickAddParser.parse(text)
                if !parsed.tags.isEmpty || parsed.priority != .none {
                    HStack(spacing: 8) {
                        if parsed.priority != .none {
                            Label(parsed.priority.localizedName, systemImage: "flag.fill")
                                .font(.caption)
                                .foregroundStyle(priorityColor(parsed.priority))
                        }
                        ForEach(parsed.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("tasks.quickAdd.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") {
                        let parsed = QuickAddParser.parse(text)
                        onSubmit(parsed, resolvedDate ?? parsed.dueDate)
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { isFocused = true }
    }

    @ViewBuilder
    private func quickDateButton(_ titleKey: LocalizedStringKey, date: QuickDate, icon: String) -> some View {
        let isSelected = selectedDate == date
        Button {
            selectedDate = date
            showCustomPicker = date == .custom
        } label: {
            Label(titleKey, systemImage: icon)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        case .none: return .secondary
        }
    }
}

// MARK: - Create List Sheet

struct CreateListSheet: View {
    let onSave: (String, String, String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var selectedColor: String = "#007AFF"
    @State private var selectedIcon: String = "list.bullet"
    @FocusState private var isFocused: Bool

    private let colors: [String] = [
        "#007AFF", "#34C759", "#FF3B30", "#FF9500",
        "#AF52DE", "#FF2D55", "#5AC8FA", "#FFCC00", "#8E8E93"
    ]

    private let icons: [String] = [
        "list.bullet", "tray.fill", "folder.fill", "star.fill",
        "heart.fill", "briefcase.fill", "book.fill", "graduationcap.fill",
        "house.fill", "cart.fill", "dumbbell.fill", "fork.knife",
        "music.note", "gamecontroller.fill", "camera.fill", "airplane",
        "car.fill", "gift.fill", "archivebox.fill", "tag.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("lists.name", text: $name)
                        .focused($isFocused)
                } header: {
                    Text("lists.name")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("lists.color")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(
                                    selectedIcon == icon
                                        ? Color(hex: selectedColor).opacity(0.2)
                                        : Color(.secondarySystemBackground)
                                )
                                .foregroundStyle(
                                    selectedIcon == icon ? Color(hex: selectedColor) : .secondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("lists.icon")
                }

                // Preview
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .foregroundStyle(Color(hex: selectedColor))
                        Text(name.isEmpty ? String(localized: "lists.previewName") : name)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                } header: {
                    Text("lists.preview")
                }
            }
            .navigationTitle("lists.new")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), selectedColor, selectedIcon)
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Confetti

private struct ConfettiItem: Identifiable {
    let id = UUID()
    let color: Color
    let offsetX: CGFloat
    let offsetY: CGFloat
    let rotation: Double
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    static func makeItems() -> [ConfettiItem] {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .teal]
        return (0..<32).map { i in
            let angle = Double(i) * (360.0 / 32.0) + Double.random(in: -10...10)
            let distance = CGFloat.random(in: 70...190)
            let radians = angle * .pi / 180
            let isCircle = i % 4 == 0
            return ConfettiItem(
                color: colors[i % colors.count],
                offsetX: cos(radians) * distance,
                offsetY: sin(radians) * distance + CGFloat.random(in: 10...60),
                rotation: Double.random(in: 180...540),
                width: isCircle ? 10 : 8,
                height: isCircle ? 10 : 14,
                cornerRadius: isCircle ? 5 : 2
            )
        }
    }
}

private struct ConfettiBurst: View {
    let onFinish: () -> Void

    @State private var moved = false
    @State private var faded = false
    @State private var items = ConfettiItem.makeItems()

    var body: some View {
        ZStack {
            ForEach(items) { item in
                RoundedRectangle(cornerRadius: item.cornerRadius)
                    .fill(item.color)
                    .frame(width: item.width, height: item.height)
                    .offset(x: moved ? item.offsetX : 0, y: moved ? item.offsetY : 0)
                    .rotationEffect(.degrees(moved ? item.rotation : 0))
                    .opacity(faded ? 0 : 1)
                    .scaleEffect(faded ? 0.3 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.65)) { moved = true }
            withAnimation(.easeIn(duration: 0.35).delay(0.5)) { faded = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { onFinish() }
        }
    }
}

// MARK: - Preview

#Preview {
    TaskListView()
}
