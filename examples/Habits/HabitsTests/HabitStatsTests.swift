import Foundation
import Testing

@testable import Habits

@MainActor
struct HabitStatsTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2  // Monday
        return calendar
    }()
    // Wednesday 2027-01-13, midday UTC.
    let today = Date(timeIntervalSince1970: 1_799_841_600)

    func days(_ offsets: Int...) -> Set<Date> {
        Set(offsets.map { calendar.date(byAdding: .day, value: -$0, to: today)! })
    }

    func stats(_ days: Set<Date>) -> HabitStats {
        HabitStats(days: days, today: today, calendar: calendar)
    }

    @Test func streakIncludesToday() {
        #expect(stats(days(0, 1, 2)).currentStreak == 3)
    }

    @Test func streakSurvivesUntilTodayIsLogged() {
        #expect(stats(days(1, 2, 3)).currentStreak == 3)
    }

    @Test func missedYesterdayBreaksStreak() {
        #expect(stats(days(2, 3, 4)).currentStreak == 0)
        #expect(stats(days(0, 2, 3)).currentStreak == 1)
    }

    @Test func longestStreakFindsBestRun() {
        #expect(stats(days(0, 1, 5, 6, 7, 8, 20)).longestStreak == 4)
        #expect(stats([]).longestStreak == 0)
    }

    @Test func completionRateCountsTodayAsPartOfPeriod() {
        #expect(stats(days(0, 1, 2, 3, 4, 5, 6)).completionRate(lastDays: 7) == 1)
        #expect(stats(days(0, 8)).completionRate(lastDays: 10) == 0.2)
        #expect(stats(days(0)).completionRate(lastDays: 0) == 0)
    }

    @Test func weeklyCountsGroupByCalendarWeek() {
        // Today is Wednesday: Mon/Tue/Wed this week, and two days last week.
        let counts = stats(days(0, 1, 2, 5, 6)).weeklyCounts(weeks: 3).map(\.count)
        #expect(counts == [0, 2, 3])
    }

    @Test func toggleAddsAndRemovesTheDay() {
        let habit = Habit(name: "Read")
        habit.toggle(on: today, calendar: calendar)
        #expect(habit.isDone(on: today, calendar: calendar))
        #expect(habit.completedDays.count == 1)
        habit.toggle(on: today.addingTimeInterval(3600), calendar: calendar)  // same day, later
        #expect(!habit.isDone(on: today, calendar: calendar))
        #expect(habit.completedDays.isEmpty)
    }
}
