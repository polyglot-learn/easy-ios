import Foundation
import SwiftData

@Model
final class Trip {
    var name: String
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \PackingItem.trip)
    var items: [PackingItem] = []

    init(name: String, startDate: Date, endDate: Date, createdAt: Date = .now) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
    }

    func nights(calendar: Calendar = .current) -> Int {
        Trip.nights(from: startDate, to: endDate, calendar: calendar)
    }

    nonisolated static func nights(from start: Date, to end: Date, calendar: Calendar) -> Int {
        max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day!)
    }

    var packedCount: Int { items.filter(\.isPacked).count }

    /// 0...1; a trip with no items counts as not started.
    var progress: Double {
        items.isEmpty ? 0 : Double(packedCount) / Double(items.count)
    }

    func isPast(now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: endDate) < calendar.startOfDay(for: now)
    }

    func addSuggestions(climate: Climate, activities: Set<Activity>, calendar: Calendar = .current) {
        let existing = Set(items.map { $0.name.lowercased() })
        for suggestion in PackingSuggestions.items(nights: nights(calendar: calendar), climate: climate, activities: activities)
        where !existing.contains(suggestion.name.lowercased()) {
            items.append(PackingItem(name: suggestion.name, category: suggestion.category, quantity: suggestion.quantity))
        }
    }
}

@Model
final class PackingItem {
    var name: String
    // Stored as a raw value so it can be used in #Predicate.
    var categoryRaw: String
    var quantity: Int
    var isPacked: Bool
    var trip: Trip?

    init(name: String, category: ItemCategory = .other, quantity: Int = 1) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.quantity = quantity
        self.isPacked = false
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

nonisolated enum ItemCategory: String, CaseIterable, Identifiable {
    case essentials, clothing, toiletries, electronics, activities, other

    var id: Self { self }

    var title: String {
        switch self {
        case .essentials: String(localized: "Essentials")
        case .clothing: String(localized: "Clothing")
        case .toiletries: String(localized: "Toiletries")
        case .electronics: String(localized: "Electronics")
        case .activities: String(localized: "Activities")
        case .other: String(localized: "Other")
        }
    }

    var symbol: String {
        switch self {
        case .essentials: "wallet.pass.fill"
        case .clothing: "tshirt.fill"
        case .toiletries: "shower.fill"
        case .electronics: "bolt.fill"
        case .activities: "figure.hiking"
        case .other: "shippingbox.fill"
        }
    }
}
