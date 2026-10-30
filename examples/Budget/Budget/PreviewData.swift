import Foundation
import SwiftData

enum PreviewData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(for: Expense.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let samples: [(String, Decimal, ExpenseCategory, Int)] = [
            ("Groceries", 84.20, .food, 0),
            ("Train pass", 45, .transport, 1),
            ("Rent", 1200, .housing, 2),
            ("Cinema", 18.50, .entertainment, 2),
            ("Pharmacy", 12.99, .health, 4),
        ]
        for (title, amount, category, daysAgo) in samples {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
            container.mainContext.insert(Expense(title: title, amount: amount, category: category, date: date))
        }
        return container
    }()
}
