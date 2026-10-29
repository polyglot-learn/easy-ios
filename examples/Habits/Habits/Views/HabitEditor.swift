import SwiftData
import SwiftUI

/// Adds a new habit when `habit` is nil, otherwise edits it.
struct HabitEditor: View {
    let habit: Habit?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var symbol = HabitStyle.symbols[0]
    @State private var colorIndex = 0

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(HabitStyle.symbols, id: \.self) { item in
                            Button {
                                symbol = item
                            } label: {
                                Image(systemName: item)
                                    .frame(width: 40, height: 40)
                                    .background(symbol == item ? HabitStyle.colors[colorIndex].opacity(0.25) : .clear, in: .circle)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item)
                            .accessibilityAddTraits(symbol == item ? .isSelected : [])
                        }
                    }
                }
                Section("Color") {
                    HStack {
                        ForEach(HabitStyle.colors.indices, id: \.self) { index in
                            Button {
                                colorIndex = index
                            } label: {
                                Circle()
                                    .fill(HabitStyle.colors[index])
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if colorIndex == index {
                                            Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Color \(index + 1)")
                        }
                    }
                }
                if let habit {
                    Section {
                        Button("Delete Habit", role: .destructive) {
                            context.delete(habit)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(trimmedName.isEmpty)
                }
            }
            .onAppear {
                guard let habit else { return }
                name = habit.name
                symbol = habit.symbol
                colorIndex = habit.colorIndex
            }
        }
    }

    private func save() {
        let target = habit ?? Habit(name: trimmedName)
        target.name = trimmedName
        target.symbol = symbol
        target.colorIndex = colorIndex
        if habit == nil { context.insert(target) }
        dismiss()
    }
}
