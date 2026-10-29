import SwiftData
import SwiftUI

@main
struct HeadlinesApp: App {
    private static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    // UI tests use canned stories so they don't depend on the network.
    @State private var feed = FeedStore(client: isUITesting ? .sample : .live)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(feed)
        }
        .modelContainer(for: Bookmark.self, inMemory: Self.isUITesting)
    }
}
