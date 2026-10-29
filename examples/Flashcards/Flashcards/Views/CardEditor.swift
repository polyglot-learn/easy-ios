import SwiftData
import SwiftUI

/// Adds a card to `deck` when `card` is nil, otherwise edits it.
struct CardEditor: View {
    let deck: Deck
    let card: Card?

    @Environment(\.dismiss) private var dismiss
    @State private var front = ""
    @State private var back = ""
    @FocusState private var focusedField: Field?

    private enum Field { case front, back }

    private func trimmed(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Front") {
                    TextField("Question", text: $front, axis: .vertical)
                        .focused($focusedField, equals: .front)
                }
                Section("Back") {
                    TextField("Answer", text: $back, axis: .vertical)
                        .focused($focusedField, equals: .back)
                }
            }
            .navigationTitle(card == nil ? "New Card" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmed(front).isEmpty || trimmed(back).isEmpty)
                }
            }
            .onAppear {
                if let card {
                    front = card.front
                    back = card.back
                } else {
                    focusedField = .front
                }
            }
        }
    }

    private func save() {
        if let card {
            card.front = trimmed(front)
            card.back = trimmed(back)
        } else {
            deck.cards.append(Card(front: trimmed(front), back: trimmed(back)))
        }
        dismiss()
    }
}
