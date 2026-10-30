import SwiftData
import SwiftUI

/// Writes a new entry when `entry` is nil, otherwise edits it.
struct EntryEditor: View {
    let entry: Entry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var mood = Mood.okay
    @State private var date = Date.now
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("How are you feeling?") {
                    HStack {
                        ForEach(Mood.allCases) { item in
                            Button {
                                withAnimation(.snappy) { mood = item }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: item.symbol)
                                        .font(.title2)
                                        .frame(width: 48, height: 48)
                                        .background(mood == item ? item.color.opacity(0.2) : .clear, in: .circle)
                                        .foregroundStyle(mood == item ? item.color : .secondary)
                                    Text(item.title).font(.caption2)
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(item.title)
                            .accessibilityAddTraits(mood == item ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section {
                    DatePicker("Date", selection: $date, in: ...Date.now)
                }
                Section("What happened today?") {
                    TextField("Write something…", text: $text, axis: .vertical)
                        .lineLimit(6...)
                }
                if let entry {
                    Section {
                        Button("Delete Entry", role: .destructive) {
                            context.delete(entry)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear {
                guard let entry else { return }
                mood = entry.mood
                date = entry.date
                text = entry.text
            }
        }
    }

    private func save() {
        let target = entry ?? Entry()
        target.mood = mood
        target.date = date
        target.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if entry == nil { context.insert(target) }
        dismiss()
    }
}
