import Foundation
import Testing

@testable import Tasks

@MainActor
struct TaskFilterTests {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_800_000_000)  // fixed "today"

    func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: now)!
    }

    @Test(arguments: [
        (-3, TaskFilter.today, true),
        (0, .today, true),
        (1, .today, false),
        (0, .upcoming, false),
        (1, .upcoming, true),
        (30, .upcoming, true),
        (-3, .open, true),
    ])
    func dueDateFilters(offset: Int, filter: TaskFilter, expected: Bool) {
        let task = TaskItem(title: "Task", dueDate: day(offset))
        #expect(filter.includes(task, now: now, calendar: calendar) == expected)
    }

    @Test func undatedTasksAreOpenButNotScheduled() {
        let task = TaskItem(title: "Someday")
        #expect(TaskFilter.open.includes(task, now: now, calendar: calendar))
        #expect(!TaskFilter.today.includes(task, now: now, calendar: calendar))
        #expect(!TaskFilter.upcoming.includes(task, now: now, calendar: calendar))
    }

    @Test func completedTasksOnlyAppearInCompleted() {
        let task = TaskItem(title: "Done", dueDate: now)
        task.toggle(now: now)
        for filter in TaskFilter.allCases {
            #expect(filter.includes(task, now: now, calendar: calendar) == (filter == .completed))
        }
    }

    @Test func toggleRecordsAndClearsCompletionDate() {
        let task = TaskItem(title: "Task")
        task.toggle(now: now)
        #expect(task.isDone && task.completedAt == now)
        task.toggle(now: now)
        #expect(!task.isDone && task.completedAt == nil)
    }

    @Test func overdueMeansBeforeToday() {
        #expect(TaskItem(title: "", dueDate: day(-1)).isOverdue(now: now, calendar: calendar))
        #expect(!TaskItem(title: "", dueDate: now).isOverdue(now: now, calendar: calendar))
    }

    @Test func sortsByDueDateThenPriorityWithUndatedLast() {
        let undated = TaskItem(title: "undated", priority: .high)
        let later = TaskItem(title: "later", dueDate: day(2))
        let soonLow = TaskItem(title: "soon-low", dueDate: day(1), priority: .low)
        let soonHigh = TaskItem(title: "soon-high", dueDate: day(1), priority: .high)
        let result = TaskFilter.open.apply(to: [undated, later, soonLow, soonHigh], now: now, calendar: calendar)
        #expect(result.map(\.title) == ["soon-high", "soon-low", "later", "undated"])
    }

    @Test func searchMatchesTitleAndNotesIgnoringCase() {
        let tasks = [
            TaskItem(title: "Buy milk"),
            TaskItem(title: "Call mom", notes: "About the MILK delivery"),
            TaskItem(title: "Walk dog"),
        ]
        let result = TaskFilter.open.apply(to: tasks, search: "milk", now: now, calendar: calendar)
        #expect(Set(result.map(\.title)) == ["Buy milk", "Call mom"])
    }
}
