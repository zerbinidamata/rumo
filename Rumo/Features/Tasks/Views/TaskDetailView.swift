import SwiftUI

/// Detailed view for a single task
struct TaskDetailView: View {
    let task: TaskItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation: Bool = false
    @State private var showPomodoro: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    Divider()

                    // Details
                    detailsSection

                    // Notes
                    if let notes = task.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }

                    // Tags
                    if let tags = task.tags, !tags.isEmpty {
                        tagsSection(tags: tags)
                    }

                    // Subtasks
                    if let subtasks = task.subtasks, !subtasks.isEmpty {
                        subtasksSection(subtasks: subtasks)
                    }

                    // Actions
                    actionsSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("tasks.detail.title")
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
                            onEdit()
                        } label: {
                            Label("common.edit", systemImage: "pencil")
                        }

                        Button {
                            showPomodoro = true
                        } label: {
                            Label("tasks.startPomodoro", systemImage: "timer")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog(
                "tasks.delete.confirmation",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("common.delete", role: .destructive) {
                    onDelete()
                }
                Button("common.cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showPomodoro) {
                PomodoroTimerView(task: task, viewModel: PomodoroViewModel())
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Completion button
                Button(action: onToggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundStyle(task.isCompleted ? .green : priorityColor)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .strikethrough(task.isCompleted)

                    if task.isCompleted, let completedAt = task.completedAt {
                        Text("tasks.completedAt \(completedAt.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Priority badge
            if task.priority != .none {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                    Text(task.priority.localizedName)
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(priorityColor.opacity(0.15))
                .foregroundStyle(priorityColor)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(spacing: 16) {
            // Due Date
            if let dueDate = task.dueDate {
                DetailRow(
                    icon: "calendar",
                    iconColor: dueDateColor(dueDate),
                    title: "tasks.dueDate",
                    value: dueDate.formatted(date: .long, time: task.hasTime ? .shortened : .omitted)
                )
            }

            // List
            if let list = task.list {
                DetailRow(
                    icon: list.icon,
                    iconColor: Color(hex: list.color),
                    title: "tasks.list",
                    value: list.name
                )
            }

            // Reminder
            if let reminder = task.reminderDate {
                DetailRow(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "tasks.reminder",
                    value: reminder.formatted(date: .abbreviated, time: .shortened)
                )
            }

            // Recurrence
            if let recurrence = task.recurrenceRule {
                DetailRow(
                    icon: "repeat",
                    iconColor: .purple,
                    title: "tasks.recurrence",
                    value: recurrence
                )
            }

            // Location
            if let location = task.locationReminder {
                DetailRow(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "tasks.location",
                    value: location
                )
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("tasks.notes", systemImage: "doc.text")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }

    // MARK: - Tags Section

    private func tagsSection(tags: [TaskTag]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("tasks.tags", systemImage: "tag.fill")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(tags) { tag in
                    Text("#\(tag.name)")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: tag.color).opacity(0.2))
                        .foregroundStyle(Color(hex: tag.color))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Subtasks Section

    private func subtasksSection(subtasks: [Subtask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("tasks.subtasks", systemImage: "checklist")
                    .font(.headline)

                Spacer()

                Text("\(subtasks.filter { $0.isCompleted }.count)/\(subtasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                ForEach(subtasks) { subtask in
                    HStack(spacing: 12) {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(subtask.isCompleted ? .green : .secondary)

                        Text(subtask.title)
                            .strikethrough(subtask.isCompleted)
                            .foregroundStyle(subtask.isCompleted ? .secondary : .primary)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                onToggleComplete()
            } label: {
                HStack {
                    Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                    Text(task.isCompleted ? "tasks.markIncomplete" : "tasks.markComplete")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(task.isCompleted ? Color(.secondarySystemBackground) : Color.green)
                .foregroundColor(task.isCompleted ? Color.primary : Color.white)
                .cornerRadius(12)
            }

            if !task.isCompleted {
                Button {
                    showPomodoro = true
                } label: {
                    HStack {
                        Image(systemName: "timer")
                        Text("tasks.startPomodoro")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Helpers

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
        }
        return .blue
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
            }

            Spacer()
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    TaskDetailView(
        task: TaskItem(
            title: "Sample Task",
            notes: "This is a sample task with some notes.",
            dueDate: Date(),
            priority: .high
        ),
        onEdit: {},
        onDelete: {},
        onToggleComplete: {}
    )
}
