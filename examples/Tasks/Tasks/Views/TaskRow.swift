import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    let onOpen: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button {
                withAnimation { task.toggle() }
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? Color.accentColor : .secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isDone ? "Mark \(task.title) as not done" : "Mark \(task.title) as done")

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .strikethrough(task.isDone)
                        .foregroundStyle(task.isDone ? .secondary : .primary)
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    if let due = task.dueDate {
                        Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(task.isOverdue() ? .red : .secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if task.priority > .none {
                Image(systemName: "flag.fill")
                    .foregroundStyle(task.priority == .high ? .red : task.priority == .medium ? .orange : .blue)
                    .accessibilityLabel("\(task.priority.title) priority")
            }
        }
    }
}
