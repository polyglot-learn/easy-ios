import Foundation
import SwiftData
import SwiftUI

@Model
final class Entry {
    var date: Date
    var text: String
    // Stored as a raw value so it can be used in #Predicate and averages.
    var moodRaw: Int

    init(date: Date = .now, text: String = "", mood: Mood = .okay) {
        self.date = date
        self.text = text
        self.moodRaw = mood.rawValue
    }

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .okay }
        set { moodRaw = newValue.rawValue }
    }
}

nonisolated enum Mood: Int, CaseIterable, Identifiable {
    case awful = 1
    case bad, okay, good, great

    var id: Self { self }

    var title: String {
        switch self {
        case .awful: String(localized: "Awful")
        case .bad: String(localized: "Bad")
        case .okay: String(localized: "Okay")
        case .good: String(localized: "Good")
        case .great: String(localized: "Great")
        }
    }

    var symbol: String {
        switch self {
        case .awful: "cloud.bolt.rain.fill"
        case .bad: "cloud.rain.fill"
        case .okay: "cloud.sun.fill"
        case .good: "sun.max.fill"
        case .great: "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .awful: .purple
        case .bad: .blue
        case .okay: .teal
        case .good: .orange
        case .great: .pink
        }
    }
}
