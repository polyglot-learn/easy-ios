import Foundation

/// Leitner spaced repetition: a correct answer moves a card up a box and
/// spaces out its next review; a wrong answer sends it back to box 1.
nonisolated enum Leitner {
    static let boxes = 1...5

    /// Days until the next review for each box.
    static func interval(for box: Int) -> Int {
        switch box {
        case ...1: 1
        case 2: 2
        case 3: 4
        case 4: 8
        default: 16
        }
    }

    static func next(box: Int, correct: Bool, now: Date, calendar: Calendar) -> (box: Int, due: Date) {
        let newBox = correct ? min(box + 1, boxes.upperBound) : boxes.lowerBound
        // Due at the start of the target day, so a card is ready first thing that morning.
        let startOfToday = calendar.startOfDay(for: now)
        let due = calendar.date(byAdding: .day, value: interval(for: newBox), to: startOfToday)!
        return (newBox, due)
    }
}
