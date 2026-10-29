import SwiftData
import SwiftUI

/// Adds a new expense when `expense` is nil, otherwise edits it.
struct ExpenseEditor: View {
    let expense: Expense?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var amount: Decimal?
    @State private var category = ExpenseCategory.food
    @State private var date = Date.now
    @State private var note = ""
    @FocusState private var amountFocused: Bool

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty && (amount ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", value: $amount, format: .currency(code: Currency.code))
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                        .focused($amountFocused)
                    TextField("What was it for?", text: $title)
                }
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { item in
                            Label(item.title, systemImage: item.symbol).tag(item)
                        }
                    }
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                    TextField("Note", text: $note, axis: .vertical)
                }
                if let expense {
                    Section {
                        Button("Delete Expense", role: .destructive) {
                            context.delete(expense)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(expense == nil ? "New Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let expense else {
            amountFocused = true
            return
        }
        title = expense.title
        amount = expense.amount
        category = expense.category
        date = expense.date
        note = expense.note
    }

    private func save() {
        guard let amount else { return }
        let target = expense ?? Expense(title: trimmedTitle, amount: amount)
        target.title = trimmedTitle
        target.amount = amount
        target.category = category
        target.date = date
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if expense == nil { context.insert(target) }
        dismiss()
    }
}
