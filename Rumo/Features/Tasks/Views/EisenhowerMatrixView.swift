import SwiftUI

/// Eisenhower Matrix: 2x2 grid of Urgent/Important quadrants
struct EisenhowerMatrixView: View {
    let tasks: [TaskItem]
    let onSelect: (TaskItem) -> Void
    let onToggle: (TaskItem) -> Void

    private var doFirst: [TaskItem]   { tasks.filter {  isUrgent($0) &&  isImportant($0) } }
    private var schedule: [TaskItem]  { tasks.filter { !isUrgent($0) &&  isImportant($0) } }
    private var delegate: [TaskItem]  { tasks.filter {  isUrgent($0) && !isImportant($0) } }
    private var eliminate: [TaskItem] { tasks.filter { !isUrgent($0) && !isImportant($0) } }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    quadrant("matrix.doFirst", tasks: doFirst, color: .red, icon: "flame.fill")
                    quadrant("matrix.schedule", tasks: schedule, color: .blue, icon: "calendar")
                }
                HStack(spacing: 0) {
                    quadrant("matrix.delegate", tasks: delegate, color: .orange, icon: "person.fill.questionmark")
                    quadrant("matrix.eliminate", tasks: eliminate, color: .secondary, icon: "trash")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 90)
        }
    }

    // MARK: - Sub-views

    private func quadrant(_ title: LocalizedStringKey, tasks: [TaskItem], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Quadrant title
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption.bold())
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }
            .foregroundStyle(color)

            // Tasks
            if tasks.isEmpty {
                Text("matrix.empty")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(tasks.prefix(5)) { task in
                    MatrixTaskRow(task: task, color: color) {
                        onSelect(task)
                    } onToggle: {
                        onToggle(task)
                    }
                }
                if tasks.count > 5 {
                    Text("matrix.more \(tasks.count - 5)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
        .padding(4)
    }

    // MARK: - Classification

    private func isUrgent(_ task: TaskItem) -> Bool {
        guard let due = task.dueDate else { return false }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: due)
        ).day ?? 999
        return days <= 1  // today, tomorrow, or overdue
    }

    private func isImportant(_ task: TaskItem) -> Bool {
        task.priority == .high || task.priority == .medium
    }
}

// MARK: - Matrix Task Row

private struct MatrixTaskRow: View {
    let task: TaskItem
    let color: Color
    let onSelect: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(task.isCompleted ? .green : color.opacity(0.7))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.caption)
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}

// MARK: - Preview

#Preview {
    EisenhowerMatrixView(tasks: [], onSelect: { _ in }, onToggle: { _ in })
}
