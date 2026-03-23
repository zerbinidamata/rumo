import SwiftUI
import SwiftData

/// Main view displaying the list of tasks with filtering and sorting
struct TaskListView: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var showQuickAdd: Bool = false
    @State private var quickAddText: String = ""
    @State private var showSortMenu: Bool = false
    @State private var showFilterMenu: Bool = false
    @State private var showListPicker: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Filter Pills
                    filterPills
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    // Task List
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
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
            }
            .navigationTitle(navigationTitle)
            .searchable(text: $viewModel.searchText, prompt: "tasks.search")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    listMenuButton
                }

                ToolbarItem(placement: .topBarTrailing) {
                    sortMenuButton
                }
            }
            .sheet(isPresented: $showQuickAdd) {
                QuickAddSheet(
                    text: $quickAddText,
                    onSubmit: { parsed in
                        Task {
                            await viewModel.createTask(
                                title: parsed.title,
                                dueDate: parsed.dueDate,
                                priority: parsed.priority
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
                .presentationDetents([.height(200)])
            }
            .sheet(isPresented: $viewModel.showTaskEditor) {
                TaskEditorView(
                    task: viewModel.editingTask,
                    lists: viewModel.lists,
                    onSave: { task in
                        Task {
                            if viewModel.editingTask != nil {
                                await viewModel.updateTask(task)
                            }
                            viewModel.showTaskEditor = false
                        }
                    },
                    onCancel: {
                        viewModel.showTaskEditor = false
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
                        Task {
                            await viewModel.toggleTaskCompletion(task)
                        }
                    }
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

            Button {
                showQuickAdd = true
            } label: {
                Label("tasks.add", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showQuickAdd = true
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
                            .foregroundStyle(Color(hex: list.color) ?? .accentColor)
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

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : priorityColor)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
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

            // Priority indicator
            if task.priority != .none {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
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

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    @Binding var text: String
    let onSubmit: (QuickAddParser.ParsedTask) -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("tasks.quickAdd.placeholder", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isFocused)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                // Parsed preview
                if !text.isEmpty {
                    let parsed = QuickAddParser.parse(text)
                    HStack(spacing: 12) {
                        if let date = parsed.dueDate {
                            Label(
                                date.formatted(date: .abbreviated, time: .shortened),
                                systemImage: "calendar"
                            )
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }

                        if parsed.priority != .none {
                            Label(
                                parsed.priority.localizedName,
                                systemImage: "flag.fill"
                            )
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
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("tasks.quickAdd.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") {
                        let parsed = QuickAddParser.parse(text)
                        onSubmit(parsed)
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
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

// MARK: - Preview

#Preview {
    TaskListView()
}
