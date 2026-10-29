import SwiftData
import SwiftUI

@main
struct ForecastApp: App {
    private static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    // UI tests use canned responses so they don't depend on the network.
    @State private var store = ForecastStore(service: isUITesting ? .sample : .live)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .modelContainer(for: SavedPlace.self, inMemory: Self.isUITesting)
    }
}
