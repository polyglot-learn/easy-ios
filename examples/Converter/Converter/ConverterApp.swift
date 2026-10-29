import SwiftUI

@main
struct ConverterApp: App {
    @State private var model = ConverterModel(defaults: Self.defaults)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }

    /// UI tests start from fresh settings every launch.
    private static var defaults: UserDefaults {
        guard ProcessInfo.processInfo.arguments.contains("-ui-testing") else { return .standard }
        let defaults = UserDefaults(suiteName: "ui-testing")!
        defaults.removePersistentDomain(forName: "ui-testing")
        return defaults
    }
}
