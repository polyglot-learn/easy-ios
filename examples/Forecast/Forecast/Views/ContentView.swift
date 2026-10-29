import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(ForecastStore.self) private var store
    @Query(sort: \SavedPlace.addedAt) private var places: [SavedPlace]
    @State private var searchText = ""
    @State private var results: [PlaceResult] = []
    @State private var searchError: String?
    @State private var isSearching = false

    private var isSearchActive: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            List {
                if isSearchActive {
                    searchResults
                } else {
                    ForEach(places) { place in
                        NavigationLink(value: place) {
                            PlaceRow(place: place)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { places[$0] }.forEach(context.delete)
                    }
                }
            }
            .overlay {
                if !isSearchActive && places.isEmpty {
                    ContentUnavailableView(
                        "No Cities",
                        systemImage: "cloud.sun",
                        description: Text("Search for a city to see its forecast.")
                    )
                }
            }
            .navigationTitle("Forecast")
            .navigationDestination(for: SavedPlace.self) { PlaceView(place: $0) }
            .searchable(text: $searchText, prompt: "Search for a city")
            .task(id: searchText) { await runSearch() }
            .refreshable {
                await store.loadAll(places.map(\.coordinate), force: true)
            }
        }
    }

    @ViewBuilder private var searchResults: some View {
        if let searchError {
            Label(searchError, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        } else if results.isEmpty && !isSearching {
            Text("No matching cities").foregroundStyle(.secondary)
        }
        ForEach(results) { result in
            let saved = places.contains { $0.coordinate == result.coordinate }
            Button {
                if !saved { context.insert(SavedPlace(result)) }
                searchText = ""
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(result.name)
                        Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: saved ? "checkmark.circle.fill" : "plus.circle.fill")
                        .foregroundStyle(saved ? Color.secondary : Color.accentColor)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(saved ? "\(result.name), \(result.subtitle), saved" : "Add \(result.name), \(result.subtitle)")
        }
    }

    private func runSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            results = []
            searchError = nil
            return
        }
        // Wait for the user to stop typing; a newer keystroke cancels this task.
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await store.search(query)
            searchError = nil
        } catch is CancellationError {
        } catch {
            searchError = String(localized: "Couldn't search. Check your connection.")
        }
    }
}

private struct PlaceRow: View {
    let place: SavedPlace
    @Environment(ForecastStore.self) private var store

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(place.name).font(.headline)
                if !place.subtitle.isEmpty {
                    Text(place.subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            switch store.state(for: place.coordinate) {
            case .loading:
                ProgressView()
            case .failed:
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.secondary)
            case .loaded(let forecast):
                Image(systemName: WeatherCode.symbol(forecast.current.code, isDay: forecast.current.isDay))
                    .symbolRenderingMode(.multicolor)
                    .accessibilityLabel(WeatherCode.description(forecast.current.code))
                Text(Format.temperature(forecast.current.temperature))
                    .font(.title2.monospacedDigit())
            }
        }
        .task { await store.load(place.coordinate) }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedPlace.self, inMemory: true)
        .environment(ForecastStore(service: .sample))
}
