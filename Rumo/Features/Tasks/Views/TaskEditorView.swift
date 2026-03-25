import SwiftUI

/// Form view for creating or editing a task
struct TaskEditorView: View {
    let task: TaskItem?
    let availableTags: [TaskTag]
    let onSave: (TaskItem, TaskList?, [TaskTag]) -> Void
    let onCancel: () -> Void
    var onCreateList: ((String, String, String) async -> TaskList?)?

    @Environment(\.dismiss) private var dismiss

    // Form State
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool = false
    @State private var hasTime: Bool = false
    @State private var priority: TaskPriority = .none
    @State private var selectedList: TaskList?
    @State private var reminderDate: Date?
    @State private var hasReminder: Bool = false
    @State private var recurrenceRule: RecurrenceOption = .none
    @State private var selectedTags: [TaskTag] = []
    @State private var subtasks: [SubtaskDraft] = []
    @State private var newSubtaskTitle: String = ""
    @State private var localLists: [TaskList]

    // UI State
    @State private var showDatePicker: Bool = false
    @State private var showReminderPicker: Bool = false
    @State private var showCreateList: Bool = false
    @FocusState private var focusedField: Field?

    init(
        task: TaskItem?,
        lists: [TaskList],
        availableTags: [TaskTag],
        onSave: @escaping (TaskItem, TaskList?, [TaskTag]) -> Void,
        onCancel: @escaping () -> Void,
        onCreateList: ((String, String, String) async -> TaskList?)? = nil
    ) {
        self.task = task
        self.availableTags = availableTags
        self.onSave = onSave
        self.onCancel = onCancel
        self.onCreateList = onCreateList
        _localLists = State(initialValue: lists)
    }

    enum Field: Hashable {
        case title
        case notes
        case subtask
    }

    enum RecurrenceOption: String, CaseIterable, Identifiable {
        case none = "None"
        case daily = "Daily"
        case weekdays = "Weekdays"
        case weekly = "Weekly"
        case biweekly = "Biweekly"
        case monthly = "Monthly"
        case yearly = "Yearly"

        var id: String { rawValue }

        var localizedName: LocalizedStringKey {
            switch self {
            case .none: return "recurrence.none"
            case .daily: return "recurrence.daily"
            case .weekdays: return "recurrence.weekdays"
            case .weekly: return "recurrence.weekly"
            case .biweekly: return "recurrence.biweekly"
            case .monthly: return "recurrence.monthly"
            case .yearly: return "recurrence.yearly"
            }
        }

        var rule: String? {
            switch self {
            case .none: return nil
            case .daily: return "FREQ=DAILY"
            case .weekdays: return "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
            case .weekly: return "FREQ=WEEKLY"
            case .biweekly: return "FREQ=WEEKLY;INTERVAL=2"
            case .monthly: return "FREQ=MONTHLY"
            case .yearly: return "FREQ=YEARLY"
            }
        }
    }

    struct SubtaskDraft: Identifiable {
        let id = UUID()
        var title: String
        var isCompleted: Bool = false
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                dateSection
                prioritySection
                listSection
                reminderSection
                recurrenceSection
                tagsSection
                subtasksSection
            }
            .navigationTitle(task == nil ? "tasks.editor.newTitle" : "tasks.editor.editTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") { saveTask() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadTaskData()
                focusedField = .title
            }
            .onChange(of: hasDueDate) { _, enabled in
                if enabled && priority == .none {
                    priority = autoPriority(for: dueDate ?? Date())
                }
            }
            .onChange(of: dueDate) { _, newDate in
                guard hasDueDate, let date = newDate else { return }
                priority = autoPriority(for: date)
                if hasReminder { reminderDate = nil }
            }
            .sheet(isPresented: $showCreateList) {
                CreateListSheet { name, color, icon in
                    Task {
                        if let newList = await onCreateList?(name, color, icon) {
                            localLists.append(newList)
                            selectedList = newList
                        }
                    }
                    showCreateList = false
                } onCancel: {
                    showCreateList = false
                }
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section {
            TextField("tasks.editor.title", text: $title)
                .font(.body)
                .focused($focusedField, equals: .title)
            TextField("tasks.editor.notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .notes)
        }
    }

    private var dateSection: some View {
        Section {
            Toggle(isOn: $hasDueDate) {
                Label("tasks.editor.dueDate", systemImage: "calendar")
            }
            if hasDueDate {
                DatePicker(
                    "tasks.editor.date",
                    selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }),
                    displayedComponents: hasTime ? [.date, .hourAndMinute] : .date
                )
                Toggle(isOn: $hasTime) {
                    Label("tasks.editor.includeTime", systemImage: "clock")
                }
            }
        }
    }

    private var prioritySection: some View {
        Section {
            Picker(selection: $priority) {
                ForEach(TaskPriority.allCases, id: \.self) { p in
                    Label(p.localizedName, systemImage: "circle.fill")
                        .foregroundStyle(colorFor(priority: p))
                        .tag(p)
                }
            } label: {
                Label("tasks.editor.priority", systemImage: "flag")
            }
        }
    }

    private var listSection: some View {
        Section {
            Picker(selection: $selectedList) {
                Text("tasks.editor.noList").tag(nil as TaskList?)
                ForEach(localLists) { list in
                    Label(list.name, systemImage: list.icon)
                        .foregroundStyle(Color(hex: list.color))
                        .tag(list as TaskList?)
                }
            } label: {
                Label("tasks.editor.list", systemImage: "folder")
            }
            if onCreateList != nil {
                Button {
                    showCreateList = true
                } label: {
                    Label("lists.new", systemImage: "plus").foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle(isOn: $hasReminder) {
                Label("tasks.editor.reminder", systemImage: "bell")
            }
            if hasReminder {
                DatePicker(
                    "tasks.editor.reminderTime",
                    selection: Binding(get: { reminderDate ?? defaultReminderDate }, set: { reminderDate = $0 }),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
    }

    private var recurrenceSection: some View {
        Section {
            Picker(selection: $recurrenceRule) {
                ForEach(RecurrenceOption.allCases) { option in
                    Text(option.localizedName).tag(option)
                }
            } label: {
                Label("tasks.editor.recurrence", systemImage: "repeat")
            }
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if !availableTags.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableTags) { tag in
                            TagChip(
                                tag: tag,
                                isSelected: selectedTags.contains { $0.id == tag.id }
                            ) {
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    selectedTags.removeAll { $0.id == tag.id }
                                } else {
                                    selectedTags.append(tag)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("tasks.editor.tags")
            }
        }
    }

    private var subtasksSection: some View {
        Section {
            ForEach($subtasks) { $subtask in
                HStack {
                    Button { subtask.isCompleted.toggle() } label: {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(subtask.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    TextField("tasks.editor.subtaskTitle", text: $subtask.title)
                }
            }
            .onDelete(perform: deleteSubtask)

            HStack {
                Image(systemName: "plus.circle").foregroundStyle(.secondary)
                TextField("tasks.editor.addSubtask", text: $newSubtaskTitle)
                    .focused($focusedField, equals: .subtask)
                    .onSubmit { addSubtask() }
                if !newSubtaskTitle.isEmpty {
                    Button("common.add") { addSubtask() }.font(.caption)
                }
            }
        } header: {
            Text("tasks.editor.subtasks")
        }
    }

    // MARK: - Computed Helpers

    private var defaultReminderDate: Date {
        guard let due = dueDate else { return Date() }
        return Calendar.current.date(byAdding: .day, value: -1, to: due) ?? due
    }

    private func autoPriority(for date: Date) -> TaskPriority {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
        switch days {
        case ..<1: return .high     // today or overdue
        case 1:    return .high     // tomorrow
        case 2...3: return .medium  // 2-3 days
        case 4...7: return .low     // within a week
        default:   return .none
        }
    }

    // MARK: - Methods

    private func loadTaskData() {
        guard let task = task else { return }

        title = task.title
        notes = task.notes ?? ""
        dueDate = task.dueDate
        hasDueDate = task.dueDate != nil
        hasTime = task.hasTime
        priority = task.priority
        selectedList = task.list
        reminderDate = task.reminderDate
        hasReminder = task.reminderDate != nil
        selectedTags = task.tags ?? []

        if let rule = task.recurrenceRule {
            recurrenceRule = RecurrenceOption.allCases.first { $0.rule == rule } ?? .none
        }

        if let taskSubtasks = task.subtasks {
            subtasks = taskSubtasks.map { SubtaskDraft(title: $0.title, isCompleted: $0.isCompleted) }
        }
    }

    private func saveTask() {
        let isNew = task == nil
        let taskToSave: TaskItem

        if let existingTask = task {
            taskToSave = existingTask
        } else {
            taskToSave = TaskItem(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority
            )
        }

        taskToSave.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        taskToSave.notes = notes.isEmpty ? nil : notes
        taskToSave.dueDate = hasDueDate ? dueDate : nil
        taskToSave.hasTime = hasTime
        taskToSave.priority = priority
        taskToSave.reminderDate = hasReminder ? reminderDate : nil
        taskToSave.recurrenceRule = recurrenceRule.rule

        // For existing tasks, set relationships directly (they share the same context).
        // For new tasks, pass them separately to avoid SwiftData auto-inserting the
        // unmanaged TaskItem when assigning a context-managed list/tag relationship.
        if !isNew {
            taskToSave.list = selectedList
            taskToSave.tags = selectedTags.isEmpty ? nil : selectedTags
        }

        // Update subtasks
        taskToSave.subtasks = subtasks.map { draft in
            Subtask(title: draft.title, isCompleted: draft.isCompleted)
        }

        onSave(taskToSave, isNew ? selectedList : nil, isNew ? selectedTags : [])
    }

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        subtasks.append(SubtaskDraft(title: trimmed))
        newSubtaskTitle = ""
    }

    private func deleteSubtask(at offsets: IndexSet) {
        subtasks.remove(atOffsets: offsets)
    }

    private func colorFor(priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        case .none: return .clear
        }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: TaskTag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark").font(.caption2)
                }
                Text("#\(tag.name)").font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: tag.color).opacity(0.2) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? Color(hex: tag.color) : Color.secondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TaskEditorView(
        task: nil,
        lists: [],
        availableTags: [],
        onSave: { _, _, _ in },
        onCancel: {}
    )
}
