import Foundation
import SwiftData

enum PreviewData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let today = Date.now
        let samples = [
            TaskItem(title: "Renew passport", dueDate: today.addingTimeInterval(-86_400 * 2), priority: .high),
            TaskItem(title: "Call the dentist", notes: "Ask about Saturday slots", dueDate: today, priority: .medium),
            TaskItem(title: "Plan weekend trip", dueDate: today.addingTimeInterval(86_400 * 4)),
            TaskItem(title: "Read chapter 3"),
        ]
        samples.forEach(container.mainContext.insert)
        return container
    }()
}
