import Foundation
import SwiftData
import Testing

@testable import Tasks

@MainActor
struct PersistenceTests {
    @Test func savesAndFetchesTasksSortedByPriority() throws {
        let container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        context.insert(TaskItem(title: "Low", priority: .low))
        context.insert(TaskItem(title: "High", priority: .high))
        try context.save()

        let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.priorityRaw, order: .reverse)])
        let fetched = try context.fetch(descriptor)
        #expect(fetched.map(\.title) == ["High", "Low"])
    }

    @Test func predicateFindsOpenHighPriorityTasks() throws {
        let container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let done = TaskItem(title: "Done", priority: .high)
        done.toggle()
        [done, TaskItem(title: "Open", priority: .high), TaskItem(title: "Low", priority: .low)].forEach(context.insert)

        let high = Priority.high.rawValue
        let fetched = try context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { !$0.isDone && $0.priorityRaw == high }))
        #expect(fetched.map(\.title) == ["Open"])
    }
}
