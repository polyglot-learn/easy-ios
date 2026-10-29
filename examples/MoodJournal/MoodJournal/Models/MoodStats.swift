import Foundation

/// A snapshot of one entry, so stats can be computed off the model objects.
nonisolated struct MoodPoint {
    let date: Date
    let mood: Int
}

nonisolated struct MoodStats {
    let points: [MoodPoint]
    let today: Date
    let calendar: Calendar

    /// Average mood (1–5) over the last `days` days including today, or nil with no entries.
    func average(lastDays days: Int) -> Double? {
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: today))!
        let recent = points.filter { $0.date >= start }
        guard !recent.isEmpty else { return nil }
        return Double(recent.map(\.mood).reduce(0, +)) / Double(recent.count)
    }

    /// One averaged value per day that has entries in the last `days` days, oldest first.
    func dailyAverages(lastDays days: Int) -> [(day: Date, mood: Double)] {
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: today))!
        return Dictionary(grouping: points.filter { $0.date >= start }) { calendar.startOfDay(for: $0.date) }
            .map { day, items in (day, Double(items.map(\.mood).reduce(0, +)) / Double(items.count)) }
            .sorted { $0.day < $1.day }
    }

    /// Consecutive days with at least one entry, ending today (or yesterday if today has none yet).
    var writingStreak: Int {
        let days = Set(points.map { calendar.startOfDay(for: $0.date) })
        var cursor = calendar.startOfDay(for: today)
        if !days.contains(cursor) { cursor = calendar.date(byAdding: .day, value: -1, to: cursor)! }
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }

    /// Indexes of points written on today's month and day in earlier years.
    var onThisDayIndexes: [Int] {
        let target = calendar.dateComponents([.month, .day, .year], from: today)
        return points.indices.filter { index in
            let c = calendar.dateComponents([.month, .day, .year], from: points[index].date)
            return c.month == target.month && c.day == target.day && c.year! < target.year!
        }
    }
}
