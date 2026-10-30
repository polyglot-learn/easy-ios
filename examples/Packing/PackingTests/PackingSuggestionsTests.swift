import Foundation
import SwiftData
import Testing

@testable import Packing

@MainActor
struct PackingSuggestionsTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    func quantity(of name: String, in items: [PackingSuggestions.Item]) -> Int? {
        items.first { $0.name == name }?.quantity
    }

    @Test(arguments: [(0, 1), (3, 4), (6, 7), (13, 7)])
    func clothingScalesWithNightsUpToAWeek(nights: Int, outfits: Int) {
        let items = PackingSuggestions.items(nights: nights, climate: .mild, activities: [])
        #expect(quantity(of: "Underwear", in: items) == outfits)
        #expect(quantity(of: "Socks", in: items) == outfits)
    }

    @Test func climateAddsMatchingClothes() {
        let cold = PackingSuggestions.items(nights: 3, climate: .cold, activities: [])
        let warm = PackingSuggestions.items(nights: 3, climate: .warm, activities: [])
        #expect(quantity(of: "Warm jacket", in: cold) == 1)
        #expect(quantity(of: "Sunscreen", in: cold) == nil)
        #expect(quantity(of: "Sunscreen", in: warm) == 1)
        #expect(quantity(of: "Shorts", in: warm) == 2)
    }

    @Test func activitiesAddItemsInStableOrder() {
        let items = PackingSuggestions.items(nights: 2, climate: .mild, activities: [.business, .beach])
        let activityNames = items.filter { $0.category == .activities }.map(\.name)
        #expect(activityNames == ["Swimsuit", "Beach towel", "Sandals"])
        #expect(quantity(of: "Business outfits", in: items) == 3)
    }

    @Test func noDuplicateNames() {
        let items = PackingSuggestions.items(nights: 10, climate: .cold, activities: Set(Activity.allCases))
        #expect(Set(items.map(\.name)).count == items.count)
    }

    @Test func nightsIgnoreTimeOfDay() {
        let start = calendar.date(from: DateComponents(year: 2027, month: 6, day: 1, hour: 22))!
        let end = calendar.date(from: DateComponents(year: 2027, month: 6, day: 4, hour: 6))!
        #expect(Trip.nights(from: start, to: end, calendar: calendar) == 3)
        #expect(Trip.nights(from: end, to: start, calendar: calendar) == 0)
    }

    @Test func addingSuggestionsTwiceDoesNotDuplicate() throws {
        let container = try ModelContainer(for: Trip.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let trip = Trip(name: "Test", startDate: .now, endDate: .now.addingTimeInterval(86_400 * 2))
        container.mainContext.insert(trip)
        trip.addSuggestions(climate: .mild, activities: [], calendar: calendar)
        let count = trip.items.count
        trip.addSuggestions(climate: .mild, activities: [], calendar: calendar)
        #expect(trip.items.count == count)
        #expect(count > 0)
    }

    @Test func progressCountsPackedItems() {
        let trip = Trip(name: "Test", startDate: .now, endDate: .now)
        #expect(trip.progress == 0)
        trip.items = [PackingItem(name: "A"), PackingItem(name: "B"), PackingItem(name: "C"), PackingItem(name: "D")]
        trip.items[0].isPacked = true
        #expect(trip.packedCount == 1)
        #expect(trip.progress == 0.25)
    }
}
