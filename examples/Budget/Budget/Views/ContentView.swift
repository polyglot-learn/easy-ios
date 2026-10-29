import Charts
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    @AppStorage("monthlyBudget") private var monthlyBudget = 2000.0
    @State private var month = Date.now
    @State private var isAdding = false
    @State private var editing: Expense?
    @State private var isEditingBudget = false

    private var summary: MonthSummary {
        MonthSummary(expenses: expenses, containing: month, budget: Decimal(monthlyBudget))
    }

    var body: some View {
        let summary = summary
        NavigationStack {
            List {
                Section {
                    MonthPicker(month: $month)
                    SummaryCard(summary: summary)
                }

                if !summary.byCategory.isEmpty {
                    Section("By category") {
                        Chart(summary.byCategory) { item in
                            SectorMark(
                                angle: .value("Amount", item.total.doubleValue),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(item.category.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 180)
                        .padding(.vertical, 8)
                        .accessibilityHidden(true)

                        ForEach(summary.byCategory) { item in
                            HStack {
                                Label(item.category.title, systemImage: item.category.symbol)
                                    .foregroundStyle(item.category.color)
                                Spacer()
                                Text(item.total, format: .currency(code: Currency.code))
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                ForEach(summary.groupedByDay(), id: \.day) { group in
                    Section(group.day.formatted(date: .complete, time: .omitted)) {
                        ForEach(group.expenses) { expense in
                            Button {
                                editing = expense
                            } label: {
                                ExpenseRow(expense: expense)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    withAnimation { context.delete(expense) }
                                }
                            }
                        }
                    }
                }
            }
            .overlay {
                if summary.expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses", systemImage: "creditcard", description: Text("Tap + to log what you spend this month.")
                    )
                    .padding(.top, 220)
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Set Budget", systemImage: "slider.horizontal.3") { isEditingBudget = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Expense", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) { ExpenseEditor(expense: nil) }
            .sheet(item: $editing) { ExpenseEditor(expense: $0) }
            .sheet(isPresented: $isEditingBudget) { BudgetSettings(monthlyBudget: $monthlyBudget) }
        }
    }
}

private struct MonthPicker: View {
    @Binding var month: Date

    var body: some View {
        HStack {
            Button("Previous Month", systemImage: "chevron.left") { shift(-1) }
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            Spacer()
            Button("Next Month", systemImage: "chevron.right") { shift(1) }
                .disabled(Calendar.current.isDate(month, equalTo: .now, toGranularity: .month))
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }

    private func shift(_ months: Int) {
        month = Calendar.current.date(byAdding: .month, value: months, to: month)!
    }
}

private struct SummaryCard: View {
    let summary: MonthSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Spent")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(summary.total, format: .currency(code: Currency.code))
                .font(.largeTitle.bold().monospacedDigit())
                .accessibilityIdentifier("monthTotal")
            ProgressView(value: min(summary.progress, 1))
                .tint(summary.progress > 1 ? .red : summary.progress > 0.85 ? .orange : .green)
            HStack {
                if summary.remaining >= 0 {
                    Text("\(summary.remaining.formatted(.currency(code: Currency.code))) left")
                } else {
                    Text("\((-summary.remaining).formatted(.currency(code: Currency.code))) over budget")
                        .foregroundStyle(.red)
                }
                Spacer()
                Text("On pace for \(summary.projectedTotal().formatted(.currency(code: Currency.code).precision(.fractionLength(0))))")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
        .padding(.vertical, 6)
    }
}

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.symbol)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(expense.category.color.gradient, in: .rect(cornerRadius: 8))
            VStack(alignment: .leading) {
                Text(expense.title)
                Text(expense.category.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(expense.amount, format: .currency(code: Currency.code))
                .monospacedDigit()
        }
        .contentShape(Rectangle())
    }
}

private struct BudgetSettings: View {
    @Binding var monthlyBudget: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Monthly budget", value: $monthlyBudget, format: .currency(code: Currency.code))
                        .keyboardType(.decimalPad)
                } footer: {
                    Text("Used to show how much you have left each month.")
                }
            }
            .navigationTitle("Monthly Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
