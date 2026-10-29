import Foundation
import SwiftData

enum PreviewData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(for: Entry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let calendar = Calendar.current
        let samples: [(Int, Mood, String)] = [
            (0, .good, "Long walk by the river after work."),
            (1, .okay, "Busy day, lots of meetings."),
            (2, .great, "Dinner with old friends!"),
            (4, .bad, "Didn't sleep well."),
            (365, .great, "First day at the new job."),
        ]
        for (daysAgo, mood, text) in samples {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
            container.mainContext.insert(Entry(date: date, text: text, mood: mood))
        }
        return container
    }()
}
