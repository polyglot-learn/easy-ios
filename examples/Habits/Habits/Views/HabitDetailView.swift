import Charts
import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @State private var isEditing = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let stats = habit.stats()
        List {
            Section {
                HStack {
                    StatView(value: "\(stats.currentStreak)", label: "Current streak")
                    Divider()
                    StatView(value: "\(stats.longestStreak)", label: "Longest streak")
                    Divider()
                    StatView(
                        value: stats.completionRate(lastDays: 30).formatted(.percent.precision(.fractionLength(0))), label: "Last 30 days")
                }
                .padding(.vertical, 8)
            }

            Section("Last 5 weeks") {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(stats.recentDays(35), id: \.self) { day in
                        let done = habit.isDone(on: day)
                        Button {
                            withAnimation { habit.toggle(on: day) }
                        } label: {
                            Text(day.formatted(.dateTime.day()))
                                .font(.caption.monospacedDigit())
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .background(done ? habit.color : Color.secondary.opacity(0.12), in: .rect(cornerRadius: 6))
                                .foregroundStyle(done ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
                        .accessibilityValue(done ? "Done" : "Not done")
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Per week") {
                Chart(stats.weeklyCounts(weeks: 8), id: \.weekStart) { week in
                    BarMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Days", week.count)
                    )
                    .foregroundStyle(habit.color.gradient)
                }
                .chartYScale(domain: 0...7)
                .frame(height: 180)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(habit.name)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) { HabitEditor(habit: habit) }
    }
}

private struct StatView: View {
    let value: String
    let label: LocalizedStringKey

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
