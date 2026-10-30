import Foundation
import Testing

@testable import MoodJournal

@MainActor
struct MoodStatsTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    // 2027-03-15 12:00 UTC
    var today: Date { calendar.date(from: DateComponents(year: 2027, month: 3, day: 15, hour: 12))! }

    func point(daysAgo: Int, mood: Int) -> MoodPoint {
        MoodPoint(date: calendar.date(byAdding: .day, value: -daysAgo, to: today)!, mood: mood)
    }

    func stats(_ points: [MoodPoint]) -> MoodStats {
        MoodStats(points: points, today: today, calendar: calendar)
    }

    @Test func averageOnlyUsesRecentDays() {
        let s = stats([point(daysAgo: 0, mood: 5), point(daysAgo: 6, mood: 3), point(daysAgo: 7, mood: 1)])
        #expect(s.average(lastDays: 7) == 4)
        #expect(stats([]).average(lastDays: 7) == nil)
    }

    @Test func dailyAveragesCombineSameDayEntries() {
        let s = stats([point(daysAgo: 0, mood: 5), point(daysAgo: 0, mood: 2), point(daysAgo: 2, mood: 4)])
        let daily = s.dailyAverages(lastDays: 30)
        #expect(daily.map(\.mood) == [4, 3.5])
    }

    @Test func writingStreak() {
        #expect(stats([point(daysAgo: 0, mood: 3), point(daysAgo: 1, mood: 3), point(daysAgo: 3, mood: 3)]).writingStreak == 2)
        #expect(stats([point(daysAgo: 1, mood: 3), point(daysAgo: 2, mood: 3)]).writingStreak == 2)
        #expect(stats([point(daysAgo: 2, mood: 3)]).writingStreak == 0)
    }

    @Test func onThisDayFindsEarlierYearsOnly() {
        let lastYear = MoodPoint(date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!, mood: 4)
        let twoYears = MoodPoint(date: calendar.date(from: DateComponents(year: 2025, month: 3, day: 15))!, mood: 2)
        let otherDay = MoodPoint(date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 16))!, mood: 4)
        let s = stats([point(daysAgo: 0, mood: 5), lastYear, otherDay, twoYears])
        #expect(s.onThisDayIndexes == [1, 3])
    }

    @Test func entryStoresMoodAsRawValue() {
        let entry = Entry(mood: .great)
        #expect(entry.moodRaw == 5)
        entry.mood = .bad
        #expect(entry.moodRaw == 2)
    }
}
