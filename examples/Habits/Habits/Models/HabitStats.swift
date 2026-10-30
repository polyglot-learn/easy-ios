import Foundation

/// Streaks and completion rates computed from the days a habit was done.
/// Pure value logic, so it isn't tied to the main actor.
nonisolated struct HabitStats {
    let days: Set<Date>
    let today: Date
    let calendar: Calendar

    init(days: Set<Date>, today: Date, calendar: Calendar) {
        self.days = Set(days.map { calendar.startOfDay(for: $0) })
        self.today = calendar.startOfDay(for: today)
        self.calendar = calendar
    }

    private func day(_ offset: Int, from date: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: date)!
    }

    /// Consecutive days up to today. If today isn't done yet, the streak
    /// still counts through yesterday, so it doesn't reset in the morning.
    var currentStreak: Int {
        var cursor = days.contains(today) ? today : day(-1, from: today)
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = day(-1, from: cursor)
        }
        return count
    }

    var longestStreak: Int {
        var longest = 0
        for start in days where !days.contains(day(-1, from: start)) {
            var length = 1
            while days.contains(day(length, from: start)) { length += 1 }
            longest = max(longest, length)
        }
        return longest
    }

    /// Share of the last `period` days (including today) that were done.
    func completionRate(lastDays period: Int) -> Double {
        guard period > 0 else { return 0 }
        let done = (0..<period).filter { days.contains(day(-$0, from: today)) }.count
        return Double(done) / Double(period)
    }

    /// Completions per week for the last `weeks` weeks, oldest first.
    func weeklyCounts(weeks: Int) -> [(weekStart: Date, count: Int)] {
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        return (0..<weeks).reversed().map { offset in
            let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeek)!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, days.filter { $0 >= start && $0 < end }.count)
        }
    }

    /// The last `count` days, oldest first.
    func recentDays(_ count: Int) -> [Date] {
        (0..<count).reversed().map { day(-$0, from: today) }
    }
}
