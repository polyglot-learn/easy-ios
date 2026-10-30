import Foundation

/// Totals for one calendar month, computed from all expenses.
struct MonthSummary {
    struct CategoryTotal: Identifiable {
        let category: ExpenseCategory
        let total: Decimal
        var id: ExpenseCategory { category }
    }

    let month: DateInterval
    let expenses: [Expense]
    let budget: Decimal
    let total: Decimal
    let byCategory: [CategoryTotal]

    init(expenses all: [Expense], containing date: Date, budget: Decimal, calendar: Calendar = .current) {
        let month = calendar.dateInterval(of: .month, for: date)!
        self.month = month
        expenses = all.filter { month.start <= $0.date && $0.date < month.end }.sorted { $0.date > $1.date }
        self.budget = budget
        total = expenses.reduce(0) { $0 + $1.amount }

        var totals: [ExpenseCategory: Decimal] = [:]
        for expense in expenses { totals[expense.category, default: 0] += expense.amount }
        byCategory =
            totals
            .map { CategoryTotal(category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    var remaining: Decimal { budget - total }

    /// 0...1 (or more when over budget). Zero when no budget is set.
    var progress: Double {
        budget > 0 ? (total / budget).doubleValue : 0
    }

    /// Spending projected to the end of the month at the current daily rate.
    /// Uses `today` to know how far into the month we are; past months use the full month.
    func projectedTotal(today: Date = .now, calendar: Calendar = .current) -> Decimal {
        let daysInMonth = calendar.range(of: .day, in: .month, for: month.start)!.count
        guard month.contains(today) else { return total }
        let daysElapsed = calendar.component(.day, from: today)
        return total / Decimal(daysElapsed) * Decimal(daysInMonth)
    }

    /// Expenses grouped by day, newest day first.
    func groupedByDay(calendar: Calendar = .current) -> [(day: Date, expenses: [Expense])] {
        Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
            .map { ($0.key, $0.value) }
            .sorted { $0.day > $1.day }
    }
}

extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
