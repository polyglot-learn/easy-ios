import SwiftData
import SwiftUI

struct DeckView: View {
    let deck: Deck

    @Environment(\.modelContext) private var context
    @State private var isAddingCard = false
    @State private var editing: Card?
    @State private var isStudying = false

    private var sortedCards: [Card] { deck.cards.sorted { $0.createdAt < $1.createdAt } }

    var body: some View {
        let due = deck.dueCards()
        List {
            Section {
                Button {
                    isStudying = true
                } label: {
                    Label(due.isEmpty ? "Nothing to review" : "Study \(due.count) due", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(due.isEmpty)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section("Progress") {
                BoxChart(cards: deck.cards)
            }

            Section("Cards") {
                ForEach(sortedCards) { card in
                    Button {
                        editing = card
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.front)
                            Text(card.back).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    offsets.map { sortedCards[$0] }.forEach(context.delete)
                }
                if deck.cards.isEmpty {
                    Text("Add your first card to start studying.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(deck.name)
        .toolbar {
            Button("Add Card", systemImage: "plus") { isAddingCard = true }
        }
        .sheet(isPresented: $isAddingCard) { CardEditor(deck: deck, card: nil) }
        .sheet(item: $editing) { CardEditor(deck: deck, card: $0) }
        .fullScreenCover(isPresented: $isStudying) { StudyView(cards: due) }
    }
}

/// How many cards are in each Leitner box.
private struct BoxChart: View {
    let cards: [Card]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Leitner.boxes, id: \.self) { box in
                let count = cards.filter { $0.box == box }.count
                VStack(spacing: 4) {
                    Text("\(count)").font(.caption.monospacedDigit())
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.3 + 0.14 * Double(box)))
                        .frame(height: max(4, 60 * CGFloat(count) / CGFloat(max(cards.count, 1))))
                    Text("Box \(box)").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(height: 100, alignment: .bottom)
        .padding(.vertical, 4)
    }
}
