import Charts
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @State private var searchText = ""
    @State private var isAdding = false
    @State private var editing: Entry?

    private var stats: MoodStats {
        MoodStats(points: entries.map { MoodPoint(date: $0.date, mood: $0.moodRaw) }, today: .now, calendar: .current)
    }

    private var visibleEntries: [Entry] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return entries }
        return entries.filter { $0.text.localizedStandardContains(query) || $0.mood.title.localizedStandardContains(query) }
    }

    private var groupedByMonth: [(month: Date, entries: [Entry])] {
        let calendar = Calendar.current
        return Dictionary(grouping: visibleEntries) { calendar.dateInterval(of: .month, for: $0.date)!.start }
            .map { ($0.key, $0.value) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        let stats = stats
        NavigationStack {
            List {
                if searchText.isEmpty && !entries.isEmpty {
                    Section {
                        OverviewCard(stats: stats)
                    }
                    let memories = stats.onThisDayIndexes.map { entries[$0] }
                    if !memories.isEmpty {
                        Section("On this day") {
                            ForEach(memories) { entry in
                                EntryRow(entry: entry, showYear: true) { editing = entry }
                            }
                        }
                    }
                }

                ForEach(groupedByMonth, id: \.month) { group in
                    Section(group.month.formatted(.dateTime.month(.wide).year())) {
                        ForEach(group.entries) { entry in
                            EntryRow(entry: entry, showYear: false) { editing = entry }
                        }
                        .onDelete { offsets in
                            offsets.map { group.entries[$0] }.forEach(context.delete)
                        }
                    }
                }
            }
            .overlay {
                if visibleEntries.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "Your Journal Is Empty", systemImage: "book.closed", description: Text("Tap + to write about your day."))
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .navigationTitle("Journal")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Entry", systemImage: "square.and.pencil") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) { EntryEditor(entry: nil) }
            .sheet(item: $editing) { EntryEditor(entry: $0) }
        }
    }
}

private struct OverviewCard: View {
    let stats: MoodStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("7-day mood").font(.caption).foregroundStyle(.secondary)
                    if let average = stats.average(lastDays: 7) {
                        let mood = Mood(rawValue: Int(average.rounded())) ?? .okay
                        Label(mood.title, systemImage: mood.symbol)
                            .font(.title3.bold())
                            .foregroundStyle(mood.color)
                    } else {
                        Text("–").font(.title3.bold())
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Writing streak").font(.caption).foregroundStyle(.secondary)
                    Text("^[\(stats.writingStreak) day](inflect: true)").font(.title3.bold())
                }
            }
            let daily = stats.dailyAverages(lastDays: 30)
            if daily.count > 1 {
                Chart(daily, id: \.day) { point in
                    LineMark(x: .value("Day", point.day, unit: .day), y: .value("Mood", point.mood))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Day", point.day, unit: .day), y: .value("Mood", point.mood))
                        .foregroundStyle((Mood(rawValue: Int(point.mood.rounded())) ?? .okay).color)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let raw = value.as(Int.self), let mood = Mood(rawValue: raw) {
                                Image(systemName: mood.symbol)
                            }
                        }
                    }
                }
                .frame(height: 120)
                .accessibilityLabel("Mood over the last 30 days")
            }
        }
        .padding(.vertical, 6)
    }
}

private struct EntryRow: View {
    let entry: Entry
    let showYear: Bool
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: entry.mood.symbol)
                    .font(.title3)
                    .foregroundStyle(entry.mood.color)
                    .frame(width: 32)
                    .accessibilityLabel(entry.mood.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        showYear ? entry.date.formatted(date: .long, time: .omitted) : entry.date.formatted(.dateTime.weekday(.wide).day())
                    )
                    .font(.subheadline.weight(.semibold))
                    if !entry.text.isEmpty {
                        Text(entry.text).lineLimit(3).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
