import Foundation

enum TaskFilter: String, CaseIterable, Identifiable {
    case open, today, upcoming, completed

    var id: Self { self }

    var title: String {
        switch self {
        case .open: String(localized: "Open")
        case .today: String(localized: "Today")
        case .upcoming: String(localized: "Upcoming")
        case .completed: String(localized: "Completed")
        }
    }

    var emptyMessage: String {
        switch self {
        case .open: String(localized: "Tap + to add your first task.")
        case .today: String(localized: "Nothing due today or overdue.")
        case .upcoming: String(localized: "No tasks due after today.")
        case .completed: String(localized: "Completed tasks show up here.")
        }
    }

    func includes(_ task: TaskItem, now: Date = .now, calendar: Calendar = .current) -> Bool {
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        switch self {
        case .open:
            return !task.isDone
        case .today:
            // Includes overdue tasks, so nothing slips through the cracks.
            guard !task.isDone, let due = task.dueDate else { return false }
            return due < startOfTomorrow
        case .upcoming:
            guard !task.isDone, let due = task.dueDate else { return false }
            return due >= startOfTomorrow
        case .completed:
            return task.isDone
        }
    }

    /// Filters, searches, and sorts tasks for display.
    func apply(to tasks: [TaskItem], search: String = "", now: Date = .now, calendar: Calendar = .current) -> [TaskItem] {
        let query = search.trimmingCharacters(in: .whitespaces)
        return
            tasks
            .filter { includes($0, now: now, calendar: calendar) }
            .filter { query.isEmpty || $0.title.localizedStandardContains(query) || $0.notes.localizedStandardContains(query) }
            .sorted(by: self == .completed ? Self.recentlyCompletedFirst : Self.mostUrgentFirst)
    }

    /// Earliest due date first (undated last), then higher priority, then oldest.
    static func mostUrgentFirst(_ a: TaskItem, _ b: TaskItem) -> Bool {
        switch (a.dueDate, b.dueDate) {
        case (let x?, let y?) where x != y: return x < y
        case (.some, nil): return true
        case (nil, .some): return false
        default:
            if a.priority != b.priority { return a.priority > b.priority }
            return a.createdAt < b.createdAt
        }
    }

    static func recentlyCompletedFirst(_ a: TaskItem, _ b: TaskItem) -> Bool {
        (a.completedAt ?? .distantPast) > (b.completedAt ?? .distantPast)
    }
}
