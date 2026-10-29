import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var tasks: [TaskItem]
    @State private var filter: TaskFilter = .open
    @State private var searchText = ""
    @State private var isAdding = false
    @State private var editing: TaskItem?

    private var visibleTasks: [TaskItem] {
        filter.apply(to: tasks, search: searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(visibleTasks) { task in
                    TaskRow(task: task) { editing = task }
                        .swipeActions(edge: .leading) {
                            Button(task.isDone ? "Reopen" : "Complete", systemImage: task.isDone ? "arrow.uturn.backward" : "checkmark") {
                                withAnimation { task.toggle() }
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                withAnimation { context.delete(task) }
                            }
                        }
                }
            }
            .overlay {
                if visibleTasks.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(filter.title, systemImage: "checklist", description: Text(filter.emptyMessage))
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                Picker("Filter", selection: $filter) {
                    ForEach(TaskFilter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Task", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) { TaskEditor(task: nil) }
            .sheet(item: $editing) { TaskEditor(task: $0) }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
