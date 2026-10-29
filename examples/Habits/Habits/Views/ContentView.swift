import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    NavigationLink(value: habit) {
                        HabitRow(habit: habit)
                    }
                }
                .onDelete { offsets in
                    offsets.map { habits[$0] }.forEach(context.delete)
                }
            }
            .overlay {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Habits Yet",
                        systemImage: "flame",
                        description: Text("Tap + to start tracking something you want to do every day.")
                    )
                }
            }
            .navigationTitle("Habits")
            .navigationDestination(for: Habit.self) { HabitDetailView(habit: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Habit", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) { HabitEditor(habit: nil) }
        }
    }
}

struct HabitRow: View {
    let habit: Habit

    var body: some View {
        let stats = habit.stats()
        HStack(spacing: 12) {
            Image(systemName: habit.symbol)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(habit.color.gradient, in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name).font(.headline)
                HStack(spacing: 4) {
                    ForEach(stats.recentDays(7), id: \.self) { day in
                        Circle()
                            .fill(habit.isDone(on: day) ? habit.color : Color.secondary.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                    Text("\(stats.currentStreak) day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }

            Spacer()

            Button {
                withAnimation { habit.toggle() }
            } label: {
                Image(systemName: habit.isDone(on: .now) ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(habit.isDone(on: .now) ? habit.color : .secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(habit.isDone(on: .now) ? "Undo \(habit.name) today" : "Mark \(habit.name) done today")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
