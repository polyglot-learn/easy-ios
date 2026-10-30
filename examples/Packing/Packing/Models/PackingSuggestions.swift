import Foundation

nonisolated enum Climate: String, CaseIterable, Identifiable {
    case warm, mild, cold
    var id: Self { self }

    var title: String {
        switch self {
        case .warm: String(localized: "Warm")
        case .mild: String(localized: "Mild")
        case .cold: String(localized: "Cold")
        }
    }
}

nonisolated enum Activity: String, CaseIterable, Identifiable {
    case beach, hiking, business
    var id: Self { self }

    var title: String {
        switch self {
        case .beach: String(localized: "Beach")
        case .hiking: String(localized: "Hiking")
        case .business: String(localized: "Business")
        }
    }
}

/// A starting packing list for a trip. Clothing scales with the length of
/// the trip, up to a week's worth (after that, plan on doing laundry).
nonisolated enum PackingSuggestions {
    struct Item: Equatable {
        let name: String
        let category: ItemCategory
        let quantity: Int
    }

    static let maxOutfits = 7

    static func items(nights: Int, climate: Climate, activities: Set<Activity>) -> [Item] {
        let days = nights + 1
        let outfits = min(days, maxOutfits)
        var list: [Item] = [
            Item(name: String(localized: "Passport or ID"), category: .essentials, quantity: 1),
            Item(name: String(localized: "Wallet"), category: .essentials, quantity: 1),
            Item(name: String(localized: "Medications"), category: .essentials, quantity: 1),
            Item(name: String(localized: "Phone charger"), category: .electronics, quantity: 1),
            Item(name: String(localized: "Underwear"), category: .clothing, quantity: outfits),
            Item(name: String(localized: "Socks"), category: .clothing, quantity: outfits),
            Item(name: String(localized: "Tops"), category: .clothing, quantity: outfits),
            Item(name: String(localized: "Pants"), category: .clothing, quantity: max(1, outfits / 3)),
            Item(name: String(localized: "Sleepwear"), category: .clothing, quantity: nights >= 7 ? 2 : 1),
            Item(name: String(localized: "Toothbrush"), category: .toiletries, quantity: 1),
            Item(name: String(localized: "Toothpaste"), category: .toiletries, quantity: 1),
            Item(name: String(localized: "Deodorant"), category: .toiletries, quantity: 1),
        ]
        if nights >= 3 {
            list.append(Item(name: String(localized: "Shampoo"), category: .toiletries, quantity: 1))
        }

        switch climate {
        case .warm:
            list += [
                Item(name: String(localized: "Shorts"), category: .clothing, quantity: max(1, outfits / 2)),
                Item(name: String(localized: "Sunglasses"), category: .essentials, quantity: 1),
                Item(name: String(localized: "Sunscreen"), category: .toiletries, quantity: 1),
            ]
        case .mild:
            list.append(Item(name: String(localized: "Light jacket"), category: .clothing, quantity: 1))
        case .cold:
            list += [
                Item(name: String(localized: "Warm jacket"), category: .clothing, quantity: 1),
                Item(name: String(localized: "Sweaters"), category: .clothing, quantity: max(1, outfits / 3)),
                Item(name: String(localized: "Gloves"), category: .clothing, quantity: 1),
                Item(name: String(localized: "Hat"), category: .clothing, quantity: 1),
            ]
        }

        // Fixed order so the list is stable regardless of Set ordering.
        for activity in Activity.allCases where activities.contains(activity) {
            switch activity {
            case .beach:
                list += [
                    Item(name: String(localized: "Swimsuit"), category: .activities, quantity: 1),
                    Item(name: String(localized: "Beach towel"), category: .activities, quantity: 1),
                    Item(name: String(localized: "Sandals"), category: .activities, quantity: 1),
                ]
            case .hiking:
                list += [
                    Item(name: String(localized: "Hiking boots"), category: .activities, quantity: 1),
                    Item(name: String(localized: "Water bottle"), category: .activities, quantity: 1),
                    Item(name: String(localized: "Rain jacket"), category: .activities, quantity: 1),
                ]
            case .business:
                list += [
                    Item(name: String(localized: "Laptop and charger"), category: .electronics, quantity: 1),
                    Item(name: String(localized: "Business outfits"), category: .clothing, quantity: min(days, 5)),
                    Item(name: String(localized: "Dress shoes"), category: .clothing, quantity: 1),
                ]
            }
        }
        return list
    }
}
