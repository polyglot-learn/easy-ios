import Foundation
import SwiftData
import Testing

@testable import Flashcards

@MainActor
struct LeitnerTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    let now = Date(timeIntervalSince1970: 1_800_000_000)  // mid-afternoon UTC

    func daysFromToday(_ date: Date) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: date).day!
    }

    @Test(arguments: [(1, 2, 2), (2, 3, 4), (3, 4, 8), (4, 5, 16), (5, 5, 16)])
    func correctAnswerMovesUpAndSpacesOut(box: Int, expectedBox: Int, expectedDays: Int) {
        let next = Leitner.next(box: box, correct: true, now: now, calendar: calendar)
        #expect(next.box == expectedBox)
        #expect(daysFromToday(next.due) == expectedDays)
    }

    @Test(arguments: 1...5)
    func wrongAnswerResetsToBoxOneTomorrow(box: Int) {
        let next = Leitner.next(box: box, correct: false, now: now, calendar: calendar)
        #expect(next.box == 1)
        #expect(daysFromToday(next.due) == 1)
    }

    @Test func dueDateIsStartOfDay() {
        let next = Leitner.next(box: 1, correct: true, now: now, calendar: calendar)
        #expect(next.due == calendar.startOfDay(for: next.due))
    }

    @Test func newCardsAreDueImmediately() {
        let card = Card(front: "Q", back: "A", createdAt: now)
        #expect(card.isDue(now: now))
        card.review(correct: true, now: now, calendar: calendar)
        #expect(!card.isDue(now: now))
        #expect(card.box == 2)
    }

    @Test func deckListsOnlyDueCardsOldestFirst() throws {
        let container = try ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let deck = Deck(name: "Test")
        container.mainContext.insert(deck)
        let learned = Card(front: "learned", back: "", createdAt: now)
        let older = Card(front: "older", back: "", createdAt: now.addingTimeInterval(-3600))
        let newer = Card(front: "newer", back: "", createdAt: now)
        deck.cards = [learned, newer, older]
        learned.review(correct: true, now: now, calendar: calendar)

        #expect(deck.dueCards(now: now).map(\.front) == ["older", "newer"])
    }

    @Test func deletingDeckDeletesItsCards() throws {
        let container = try ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let deck = Deck(name: "Test")
        context.insert(deck)
        deck.cards.append(Card(front: "Q", back: "A"))
        try context.save()

        context.delete(deck)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Card>()) == 0)
    }
}
