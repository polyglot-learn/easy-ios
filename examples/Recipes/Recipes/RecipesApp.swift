import SwiftData
import SwiftUI

@main
struct RecipesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: Recipe.self,
            inMemory: ProcessInfo.processInfo.arguments.contains("-ui-testing")
        )
    }
}
