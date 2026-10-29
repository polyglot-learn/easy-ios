import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @State private var isAdding = false

    private var upcoming: [Trip] { trips.filter { !$0.isPast() } }
    private var past: [Trip] { trips.filter { $0.isPast() }.reversed() }

    var body: some View {
        NavigationStack {
            List {
                if !upcoming.isEmpty {
                    Section("Upcoming") { rows(upcoming) }
                }
                if !past.isEmpty {
                    Section("Past") { rows(past) }
                }
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "No Trips",
                        systemImage: "suitcase.rolling",
                        description: Text("Tap + to plan a trip and get a packing list to start from.")
                    )
                }
            }
            .navigationTitle("Packing")
            .navigationDestination(for: Trip.self) { TripView(trip: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Trip", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) { NewTripView() }
        }
    }

    private func rows(_ trips: [Trip]) -> some View {
        ForEach(trips) { trip in
            NavigationLink(value: trip) {
                HStack(spacing: 14) {
                    ProgressRing(progress: trip.progress)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.name).font(.headline)
                        Text(trip.startDate.formatted(.dateTime.month().day()) + " – " + trip.endDate.formatted(.dateTime.month().day()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onDelete { offsets in
            offsets.map { trips[$0] }.forEach(context.delete)
        }
    }
}

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress >= 1 ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress >= 1 {
                Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.green)
            }
        }
        .frame(width: 36, height: 36)
        .accessibilityElement()
        .accessibilityLabel("Packed")
        .accessibilityValue(progress.formatted(.percent.precision(.fractionLength(0))))
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
