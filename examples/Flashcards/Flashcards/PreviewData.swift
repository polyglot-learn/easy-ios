import Foundation
import SwiftData

enum PreviewData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let spanish = Deck(name: "Spanish basics")
        container.mainContext.insert(spanish)
        for (front, back) in [("Hello", "Hola"), ("Thank you", "Gracias"), ("Goodbye", "Adiós"), ("Please", "Por favor")] {
            spanish.cards.append(Card(front: front, back: back))
        }
        spanish.cards.first?.review(correct: true)
        return container
    }()
}
