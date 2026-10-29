import SwiftData
import SwiftUI

/// Adds a new task when `task` is nil, otherwise edits it.
struct TaskEditor: View {
    let task: TaskItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date.now
    @State private var priority = Priority.none
    @FocusState private var titleFocused: Bool

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .focused($titleFocused)
                        .submitLabel(.done)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Toggle("Due date", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { Text($0.title).tag($0) }
                    }
                }
                if let task {
                    Section {
                        Button("Delete Task", role: .destructive) {
                            context.delete(task)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let task else {
            titleFocused = true
            return
        }
        title = task.title
        notes = task.notes
        hasDueDate = task.dueDate != nil
        dueDate = task.dueDate ?? .now
        priority = task.priority
    }

    private func save() {
        let target = task ?? TaskItem(title: trimmedTitle)
        target.title = trimmedTitle
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        target.dueDate = hasDueDate ? dueDate : nil
        target.priority = priority
        if task == nil { context.insert(target) }
        dismiss()
    }
}
