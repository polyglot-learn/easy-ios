import Foundation
import SwiftData

enum PreviewData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(for: Trip.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let calendar = Calendar.current
        let lisbon = Trip(
            name: "Lisbon",
            startDate: calendar.date(byAdding: .day, value: 5, to: .now)!,
            endDate: calendar.date(byAdding: .day, value: 9, to: .now)!
        )
        container.mainContext.insert(lisbon)
        lisbon.addSuggestions(climate: .warm, activities: [.beach])
        for item in lisbon.items.prefix(5) { item.isPacked = true }
        return container
    }()
}
