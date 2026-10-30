import Foundation
import SwiftData

@Model
final class Deck {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }

    func dueCards(now: Date = .now) -> [Card] {
        cards.filter { $0.isDue(now: now) }.sorted { $0.dueDate < $1.dueDate }
    }
}

@Model
final class Card {
    var front: String
    var back: String
    /// Leitner box, 1 (learning) through 5 (well known).
    var box: Int
    var dueDate: Date
    var createdAt: Date
    var deck: Deck?

    init(front: String, back: String, createdAt: Date = .now) {
        self.front = front
        self.back = back
        self.box = 1
        self.dueDate = createdAt
        self.createdAt = createdAt
    }

    func isDue(now: Date = .now) -> Bool {
        dueDate <= now
    }

    func review(correct: Bool, now: Date = .now, calendar: Calendar = .current) {
        let next = Leitner.next(box: box, correct: correct, now: now, calendar: calendar)
        box = next.box
        dueDate = next.due
    }
}
