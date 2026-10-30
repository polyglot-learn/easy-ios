import SwiftData
import SwiftUI

@main
struct PackingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: Trip.self,
            inMemory: ProcessInfo.processInfo.arguments.contains("-ui-testing")
        )
    }
}
