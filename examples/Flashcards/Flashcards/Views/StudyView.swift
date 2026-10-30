import SwiftUI

/// Reviews a fixed set of due cards one at a time.
struct StudyView: View {
    let cards: [Card]

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var showingAnswer = false
    @State private var correctCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if index < cards.count {
                    ProgressView(value: Double(index), total: Double(cards.count))
                        .accessibilityLabel("Card \(index + 1) of \(cards.count)")
                    card(cards[index])
                    controls
                } else {
                    finished
                }
            }
            .padding()
            .navigationTitle("Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func card(_ card: Card) -> some View {
        Button {
            withAnimation(.spring) { showingAnswer.toggle() }
        } label: {
            VStack(spacing: 16) {
                Text(showingAnswer ? "Answer" : "Question")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(showingAnswer ? card.back : card.front)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                if !showingAnswer {
                    Text("Tap to reveal")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background.secondary, in: .rect(cornerRadius: 20))
            .rotation3DEffect(.degrees(showingAnswer ? 360 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var controls: some View {
        if showingAnswer {
            HStack(spacing: 16) {
                Button {
                    answer(correct: false)
                } label: {
                    Label("Again", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
                .tint(.orange)
                Button {
                    answer(correct: true)
                } label: {
                    Label("Got It", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .tint(.green)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else {
            Button {
                withAnimation(.spring) { showingAnswer = true }
            } label: {
                Text("Show Answer").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var finished: some View {
        ContentUnavailableView {
            Label("All Done", systemImage: "checkmark.seal.fill")
        } description: {
            Text("You got \(correctCount) of \(cards.count) right. Cards you missed will come back tomorrow.")
        } actions: {
            Button("Finish") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func answer(correct: Bool) {
        cards[index].review(correct: correct)
        if correct { correctCount += 1 }
        showingAnswer = false
        withAnimation { index += 1 }
    }
}
