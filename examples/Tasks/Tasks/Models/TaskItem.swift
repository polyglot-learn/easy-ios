import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var notes: String
    var dueDate: Date?
    // Stored as a raw value so it can be used in #Predicate and sorting.
    var priorityRaw: Int
    var isDone: Bool
    var createdAt: Date
    var completedAt: Date?

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: Priority = .none,
        createdAt: Date = .now
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.isDone = false
        self.createdAt = createdAt
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .none }
        set { priorityRaw = newValue.rawValue }
    }

    func toggle(now: Date = .now) {
        isDone.toggle()
        completedAt = isDone ? now : nil
    }

    /// Due before today and not done.
    func isOverdue(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard !isDone, let dueDate else { return false }
        return dueDate < calendar.startOfDay(for: now)
    }
}

enum Priority: Int, CaseIterable, Identifiable, Comparable {
    case none, low, medium, high

    var id: Self { self }

    var title: String {
        switch self {
        case .none: String(localized: "None")
        case .low: String(localized: "Low")
        case .medium: String(localized: "Medium")
        case .high: String(localized: "High")
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
