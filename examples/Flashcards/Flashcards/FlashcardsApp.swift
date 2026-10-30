import SwiftData
import SwiftUI

@main
struct FlashcardsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: Deck.self,
            inMemory: ProcessInfo.processInfo.arguments.contains("-ui-testing")
        )
    }
}
