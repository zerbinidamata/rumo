import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel managing tasks list state and operations
@MainActor
final class TasksViewModel: ObservableObject {

    // MARK: - Published State

    @Published var tasks: [TaskItem] = []
    @Published var selectedList: TaskList?
    @Published var lists: [TaskList] = []
    @Published var tags: [TaskTag] = []
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .dueDate
    @Published var filterOption: FilterOption = .all
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false

    // MARK: - Selection State

    @Published var selectedTask: TaskItem?
    @Published var showTaskDetail: Bool = false
    @Published var showTaskEditor: Bool = false
    @Published var editingTask: TaskItem?

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let context: ModelContext
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Enums

    enum SortOption: String, CaseIterable, Identifiable {
        case urgency = "Urgency"
        case dueDate = "Due Date"
        case priority = "Priority"
        case title = "Title"
        case createdAt = "Created"

        var id: String { rawValue }

        var localizedName: LocalizedStringKey {
            switch self {
            case .urgency: return "sort.urgency"
            case .dueDate: return "sort.dueDate"
            case .priority: return "sort.priority"
            case .title: return "sort.title"
            case .createdAt: return "sort.created"
            }
        }
    }

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case today = "Today"
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case completed = "Completed"

        var id: String { rawValue }

        var localizedName: LocalizedStringKey {
            switch self {
            case .all: return "filter.all"
            case .today: return "filter.today"
            case .upcoming: return "filter.upcoming"
            case .overdue: return "filter.overdue"
            case .completed: return "filter.completed"
            }
        }
    }

    // MARK: - Initialization

    init(modelContainer: ModelContainer = .shared) {
        self.modelContainer = modelContainer
        self.context = ModelContext(modelContainer)
        setupSearchDebounce()
    }

    // MARK: - Data Loading

    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }

        let context = self.context

        do {
            // Load lists
            let listDescriptor = FetchDescriptor<TaskList>(
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            lists = try context.fetch(listDescriptor)

            // Load tags
            let tagDescriptor = FetchDescriptor<TaskTag>(
                sortBy: [SortDescriptor(\.name)]
            )
            tags = try context.fetch(tagDescriptor)

            // Load tasks based on current filters
            var predicate: Predicate<TaskItem>?

            // Build predicate based on filter and selected list
            if let list = selectedList {
                let listId = list.id
                predicate = #Predicate<TaskItem> { task in
                    task.list?.id == listId
                }
            }

            var descriptor = FetchDescriptor<TaskItem>(predicate: predicate)

            // Apply sorting
            switch sortOption {
            case .urgency:
                descriptor.sortBy = [SortDescriptor(\.dueDate, order: .forward)]
            case .dueDate:
                descriptor.sortBy = [SortDescriptor(\.dueDate, order: .forward)]
            case .priority:
                descriptor.sortBy = [SortDescriptor(\.priorityValue, order: .reverse)]
            case .title:
                descriptor.sortBy = [SortDescriptor(\.title)]
            case .createdAt:
                descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
            }

            var fetchedTasks = try context.fetch(descriptor)

            if sortOption == .urgency {
                fetchedTasks = fetchedTasks.sorted { urgencyScore($0) > urgencyScore($1) }
            }

            // Apply filter
            fetchedTasks = applyFilter(to: fetchedTasks)

            // Apply search
            if !searchText.isEmpty {
                fetchedTasks = fetchedTasks.filter { task in
                    task.title.localizedCaseInsensitiveContains(searchText) ||
                    (task.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            }

            tasks = fetchedTasks

        } catch {
            self.error = error
            self.showError = true
        }
    }

    func loadLists() async {
        let context = self.context

        do {
            let descriptor = FetchDescriptor<TaskList>(
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            lists = try context.fetch(descriptor)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Task Operations

    func createTask(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: TaskPriority = .none,
        list: TaskList? = nil,
        tagNames: [String] = []
    ) async {
        let context = self.context

        let task = TaskItem(
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: priority
        )

        task.list = list ?? selectedList

        if !tagNames.isEmpty {
            let allTags = (try? context.fetch(FetchDescriptor<TaskTag>())) ?? []
            var taskTags: [TaskTag] = []
            for name in tagNames {
                let lower = name.lowercased()
                if let existing = allTags.first(where: { $0.name.lowercased() == lower }) {
                    taskTags.append(existing)
                } else {
                    let newTag = TaskTag(name: name)
                    context.insert(newTag)
                    taskTags.append(newTag)
                }
            }
            task.tags = taskTags
        }

        context.insert(task)

        do {
            try context.save()
            await loadTasks()

            // Award XP for creating a task
            await ProfileManager.shared.addXP(5)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func updateTask(_ task: TaskItem) async {
        let context = self.context

        task.updatedAt = Date()
        task.markAsModified()

        do {
            try context.save()
            await loadTasks()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func toggleTaskCompletion(_ task: TaskItem) async {
        let context = self.context

        let wasCompleted = task.isCompleted
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        task.updatedAt = Date()
        task.markAsModified()

        do {
            try context.save()

            // Award XP for completing a task
            if task.isCompleted && !wasCompleted {
                let xp = task.priority.xpValue
                await ProfileManager.shared.addXP(xp)
                await ProfileManager.shared.incrementStat(.taskCompleted)
            }

            await loadTasks()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func deleteTask(_ task: TaskItem) async {
        let context = self.context

        context.delete(task)

        do {
            try context.save()
            await loadTasks()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func deleteTasks(at offsets: IndexSet) async {
        let tasksToDelete = offsets.map { tasks[$0] }

        let context = self.context

        for task in tasksToDelete {
            context.delete(task)
        }

        do {
            try context.save()
            await loadTasks()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func moveTask(_ task: TaskItem, to list: TaskList) async {
        let context = self.context

        task.list = list
        task.updatedAt = Date()
        task.markAsModified()

        do {
            try context.save()
            await loadTasks()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func reorderTasks(from source: IndexSet, to destination: Int) async {
        var reorderedTasks = tasks
        reorderedTasks.move(fromOffsets: source, toOffset: destination)

        let context = self.context

        for (index, task) in reorderedTasks.enumerated() {
            task.sortOrder = index
            task.updatedAt = Date()
        }

        do {
            try context.save()
            tasks = reorderedTasks
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - List Operations

    func createList(name: String, color: String, icon: String) async {
        _ = await createListAndReturn(name: name, color: color, icon: icon)
    }

    func createListAndReturn(name: String, color: String, icon: String) async -> TaskList? {
        let context = self.context

        let list = TaskList(name: name, color: color, icon: icon)
        list.sortOrder = lists.count

        context.insert(list)

        do {
            try context.save()
            await loadLists()
            return lists.first { $0.name == name }
        } catch {
            self.error = error
            self.showError = true
            return nil
        }
    }

    func deleteList(_ list: TaskList) async {
        let context = self.context

        // Move tasks to inbox or delete them
        for task in list.tasks ?? [] {
            context.delete(task)
        }

        context.delete(list)

        do {
            try context.save()
            if selectedList?.id == list.id {
                selectedList = nil
            }
            await loadLists()
            await loadTasks()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Selection

    func selectTask(_ task: TaskItem) {
        selectedTask = task
        showTaskDetail = true
    }

    func editTask(_ task: TaskItem) {
        editingTask = task
        showTaskEditor = true
    }

    func createNewTask() {
        editingTask = nil
        showTaskEditor = true
    }

    // MARK: - Filtering

    func selectList(_ list: TaskList?) {
        selectedList = list
        Task {
            await loadTasks()
        }
    }

    func setFilter(_ filter: FilterOption) {
        filterOption = filter
        Task {
            await loadTasks()
        }
    }

    func setSort(_ sort: SortOption) {
        sortOption = sort
        Task {
            await loadTasks()
        }
    }

    // MARK: - Smart Lists

    var todayTasks: [TaskItem] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate) && !task.isCompleted
        }
    }

    var overdueTasks: [TaskItem] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && !task.isCompleted
        }
    }

    var upcomingTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today)!

        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate > today && dueDate <= weekFromNow && !task.isCompleted
        }
    }

    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
    }

    var incompleteTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    // MARK: - Private Methods

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.loadTasks()
                }
            }
            .store(in: &cancellables)
    }

    private func applyFilter(to tasks: [TaskItem]) -> [TaskItem] {
        switch filterOption {
        case .all:
            return tasks.filter { !$0.isCompleted }
        case .today:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate) && !task.isCompleted
            }
        case .upcoming:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today)!

            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate > today && dueDate <= weekFromNow && !task.isCompleted
            }
        case .overdue:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate < Date() && !task.isCompleted
            }
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }

    func clearError() {
        error = nil
        showError = false
    }

    private func urgencyScore(_ task: TaskItem) -> Int {
        let calendar = Calendar.current
        var score = 0

        // Time component: closer due date = higher score
        if let due = task.dueDate {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: due)).day ?? 999
            switch days {
            case ..<0:  score += 100  // overdue
            case 0:     score += 80   // today
            case 1:     score += 60   // tomorrow
            case 2...3: score += 40
            case 4...7: score += 20
            default:    score += 5
            }
        }

        // Priority component
        score += task.priority.rawValue * 10

        return score
    }
}

// MARK: - TaskPriority Extension

extension TaskPriority {
    var xpValue: Int {
        switch self {
        case .none: return 10
        case .low: return 15
        case .medium: return 20
        case .high: return 30
        }
    }
}
