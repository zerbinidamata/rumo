import SwiftUI

/// Form view for creating or editing a task
struct TaskEditorView: View {
    let task: TaskItem?
    let lists: [TaskList]
    let onSave: (TaskItem) -> Void
    let onCancel: () -> Void

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
    @State private var subtasks: [SubtaskDraft] = []
    @State private var newSubtaskTitle: String = ""

    // UI State
    @State private var showDatePicker: Bool = false
    @State private var showReminderPicker: Bool = false
    @FocusState private var focusedField: Field?

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
                // Title Section
                Section {
                    TextField("tasks.editor.title", text: $title)
                        .font(.body)
                        .focused($focusedField, equals: .title)

                    TextField("tasks.editor.notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                }

                // Date & Time Section
                Section {
                    Toggle(isOn: $hasDueDate) {
                        Label("tasks.editor.dueDate", systemImage: "calendar")
                    }

                    if hasDueDate {
                        DatePicker(
                            "tasks.editor.date",
                            selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ),
                            displayedComponents: hasTime ? [.date, .hourAndMinute] : .date
                        )

                        Toggle(isOn: $hasTime) {
                            Label("tasks.editor.includeTime", systemImage: "clock")
                        }
                    }
                }

                // Priority Section
                Section {
                    Picker(selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            HStack {
                                Circle()
                                    .fill(colorFor(priority: p))
                                    .frame(width: 12, height: 12)
                                Text(p.localizedName)
                            }
                            .tag(p)
                        }
                    } label: {
                        Label("tasks.editor.priority", systemImage: "flag")
                    }
                }

                // List Section
                Section {
                    Picker(selection: $selectedList) {
                        Text("tasks.editor.noList")
                            .tag(nil as TaskList?)

                        ForEach(lists) { list in
                            HStack {
                                Image(systemName: list.icon)
                                    .foregroundStyle(Color(hex: list.color) ?? .accentColor)
                                Text(list.name)
                            }
                            .tag(list as TaskList?)
                        }
                    } label: {
                        Label("tasks.editor.list", systemImage: "folder")
                    }
                }

                // Reminder Section
                Section {
                    Toggle(isOn: $hasReminder) {
                        Label("tasks.editor.reminder", systemImage: "bell")
                    }

                    if hasReminder {
                        DatePicker(
                            "tasks.editor.reminderTime",
                            selection: Binding(
                                get: { reminderDate ?? (dueDate ?? Date()) },
                                set: { reminderDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // Recurrence Section
                Section {
                    Picker(selection: $recurrenceRule) {
                        ForEach(RecurrenceOption.allCases) { option in
                            Text(option.localizedName)
                                .tag(option)
                        }
                    } label: {
                        Label("tasks.editor.recurrence", systemImage: "repeat")
                    }
                }

                // Subtasks Section
                Section {
                    ForEach($subtasks) { $subtask in
                        HStack {
                            Button {
                                subtask.isCompleted.toggle()
                            } label: {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(subtask.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)

                            TextField("tasks.editor.subtaskTitle", text: $subtask.title)
                        }
                    }
                    .onDelete(perform: deleteSubtask)

                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.secondary)

                        TextField("tasks.editor.addSubtask", text: $newSubtaskTitle)
                            .focused($focusedField, equals: .subtask)
                            .onSubmit {
                                addSubtask()
                            }

                        if !newSubtaskTitle.isEmpty {
                            Button("common.add") {
                                addSubtask()
                            }
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("tasks.editor.subtasks")
                }
            }
            .navigationTitle(task == nil ? "tasks.editor.newTitle" : "tasks.editor.editTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadTaskData()
                focusedField = .title
            }
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

        if let rule = task.recurrenceRule {
            recurrenceRule = RecurrenceOption.allCases.first { $0.rule == rule } ?? .none
        }

        if let taskSubtasks = task.subtasks {
            subtasks = taskSubtasks.map { SubtaskDraft(title: $0.title, isCompleted: $0.isCompleted) }
        }
    }

    private func saveTask() {
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
        taskToSave.list = selectedList
        taskToSave.reminderDate = hasReminder ? reminderDate : nil
        taskToSave.recurrenceRule = recurrenceRule.rule

        // Update subtasks
        taskToSave.subtasks = subtasks.map { draft in
            Subtask(title: draft.title, isCompleted: draft.isCompleted)
        }

        onSave(taskToSave)
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

// MARK: - Preview

#Preview {
    TaskEditorView(
        task: nil,
        lists: [],
        onSave: { _ in },
        onCancel: {}
    )
}
