import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var name: String
    var symbol: String
    var colorIndex: Int
    var createdAt: Date
    /// Start-of-day dates on which the habit was done.
    var completedDays: [Date]

    init(name: String, symbol: String = "star.fill", colorIndex: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.symbol = symbol
        self.colorIndex = colorIndex
        self.createdAt = createdAt
        self.completedDays = []
    }

    var color: Color { HabitStyle.colors[colorIndex % HabitStyle.colors.count] }

    func isDone(on date: Date, calendar: Calendar = .current) -> Bool {
        completedDays.contains(calendar.startOfDay(for: date))
    }

    func toggle(on date: Date = .now, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: date)
        if let index = completedDays.firstIndex(of: day) {
            completedDays.remove(at: index)
        } else {
            completedDays.append(day)
        }
    }

    func stats(today: Date = .now, calendar: Calendar = .current) -> HabitStats {
        HabitStats(days: Set(completedDays), today: today, calendar: calendar)
    }
}

nonisolated enum HabitStyle {
    static let colors: [Color] = [.orange, .red, .pink, .purple, .blue, .teal, .green, .yellow]
    static let symbols = [
        "star.fill", "figure.walk", "figure.run", "drop.fill", "bed.double.fill", "book.fill",
        "brain.head.profile", "leaf.fill", "dumbbell.fill", "fork.knife", "pills.fill", "heart.fill",
    ]
}
