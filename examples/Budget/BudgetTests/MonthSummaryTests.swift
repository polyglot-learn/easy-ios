import Foundation
import Testing

@testable import Budget

@MainActor
struct MonthSummaryTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    var sample: [Expense] {
        [
            Expense(title: "Lunch", amount: Decimal(string: "12.50")!, category: .food, date: date(2027, 4, 3)),
            Expense(title: "Dinner", amount: Decimal(string: "30.25")!, category: .food, date: date(2027, 4, 10)),
            Expense(title: "Bus", amount: 2, category: .transport, date: date(2027, 4, 10)),
            Expense(title: "Last month", amount: 500, category: .housing, date: date(2027, 3, 31)),
            Expense(title: "Next month", amount: 99, category: .other, date: date(2027, 5, 1)),
        ]
    }

    @Test func onlyIncludesExpensesInTheMonth() {
        let summary = MonthSummary(expenses: sample, containing: date(2027, 4, 15), budget: 100, calendar: calendar)
        #expect(summary.expenses.map(\.title).sorted() == ["Bus", "Dinner", "Lunch"])
        #expect(summary.total == Decimal(string: "44.75")!)
    }

    @Test func decimalTotalsAvoidFloatingPointErrors() {
        let cents = (0..<10).map { _ in Expense(title: "x", amount: Decimal(string: "0.10")!, date: date(2027, 4, 1)) }
        let summary = MonthSummary(expenses: cents, containing: date(2027, 4, 1), budget: 0, calendar: calendar)
        #expect(summary.total == 1)
    }

    @Test func categoriesAreSortedByTotal() {
        let summary = MonthSummary(expenses: sample, containing: date(2027, 4, 15), budget: 100, calendar: calendar)
        #expect(summary.byCategory.map(\.category) == [.food, .transport])
        #expect(summary.byCategory.first?.total == Decimal(string: "42.75")!)
    }

    @Test func remainingAndProgress() {
        let summary = MonthSummary(expenses: sample, containing: date(2027, 4, 15), budget: 50, calendar: calendar)
        #expect(summary.remaining == Decimal(string: "5.25")!)
        #expect(abs(summary.progress - 0.895) < 0.0001)
        #expect(MonthSummary(expenses: [], containing: .now, budget: 0, calendar: calendar).progress == 0)
    }

    @Test func projectsCurrentMonthAtDailyRate() {
        // April has 30 days; 44.75 spent by April 10 -> 4.475/day -> 134.25.
        let summary = MonthSummary(expenses: sample, containing: date(2027, 4, 10), budget: 0, calendar: calendar)
        #expect(summary.projectedTotal(today: date(2027, 4, 10), calendar: calendar) == Decimal(string: "134.25")!)
        // A past month is already complete.
        #expect(summary.projectedTotal(today: date(2027, 6, 1), calendar: calendar) == Decimal(string: "44.75")!)
    }

    @Test func groupsByDayNewestFirst() {
        let summary = MonthSummary(expenses: sample, containing: date(2027, 4, 15), budget: 0, calendar: calendar)
        let groups = summary.groupedByDay(calendar: calendar)
        #expect(groups.map(\.expenses.count) == [2, 1])
        #expect(groups.first?.day == calendar.startOfDay(for: date(2027, 4, 10)))
    }
}
