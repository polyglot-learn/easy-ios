import Foundation
import SwiftData
import SwiftUI

@Model
final class Expense {
    var title: String
    var amount: Decimal
    // Stored as a raw value so it can be used in #Predicate.
    var categoryRaw: String
    var date: Date
    var note: String

    init(title: String, amount: Decimal, category: ExpenseCategory = .other, date: Date = .now, note: String = "") {
        self.title = title
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.date = date
        self.note = note
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case food, transport, housing, bills, shopping, entertainment, health, other

    var id: Self { self }

    var title: String {
        switch self {
        case .food: String(localized: "Food")
        case .transport: String(localized: "Transport")
        case .housing: String(localized: "Housing")
        case .bills: String(localized: "Bills")
        case .shopping: String(localized: "Shopping")
        case .entertainment: String(localized: "Entertainment")
        case .health: String(localized: "Health")
        case .other: String(localized: "Other")
        }
    }

    var symbol: String {
        switch self {
        case .food: "fork.knife"
        case .transport: "car.fill"
        case .housing: "house.fill"
        case .bills: "doc.text.fill"
        case .shopping: "bag.fill"
        case .entertainment: "popcorn.fill"
        case .health: "cross.case.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: .orange
        case .transport: .blue
        case .housing: .brown
        case .bills: .indigo
        case .shopping: .pink
        case .entertainment: .purple
        case .health: .red
        case .other: .gray
        }
    }
}

enum Currency {
    /// The user's local currency, e.g. "USD".
    static var code: String { Locale.current.currency?.identifier ?? "USD" }
}
