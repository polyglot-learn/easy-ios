import Foundation
import SwiftData

enum PreviewData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(for: Habit.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let calendar = Calendar.current
        let walk = Habit(name: "Walk 10k steps", symbol: "figure.walk", colorIndex: 6)
        let water = Habit(name: "Drink water", symbol: "drop.fill", colorIndex: 4)
        for offset in 0..<20 where offset % 4 != 3 {
            walk.toggle(on: calendar.date(byAdding: .day, value: -offset, to: .now)!)
        }
        for offset in 1..<6 {
            water.toggle(on: calendar.date(byAdding: .day, value: -offset, to: .now)!)
        }
        [walk, water].forEach(container.mainContext.insert)
        return container
    }()
}
