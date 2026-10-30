import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.createdAt) private var decks: [Deck]
    @State private var isNaming = false
    @State private var newDeckName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(decks) { deck in
                    NavigationLink(value: deck) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deck.name).font(.headline)
                            Text("^[\(deck.cards.count) card](inflect: true) · \(deck.dueCards().count) due")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    offsets.map { decks[$0] }.forEach(context.delete)
                }
            }
            .overlay {
                if decks.isEmpty {
                    ContentUnavailableView(
                        "No Decks",
                        systemImage: "rectangle.on.rectangle.angled",
                        description: Text("Create a deck for each subject you're learning.")
                    )
                }
            }
            .navigationTitle("Flashcards")
            .navigationDestination(for: Deck.self) { DeckView(deck: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Deck", systemImage: "plus") {
                        newDeckName = ""
                        isNaming = true
                    }
                }
            }
            .alert("New Deck", isPresented: $isNaming) {
                TextField("Name", text: $newDeckName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    let name = newDeckName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty { context.insert(Deck(name: name)) }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
