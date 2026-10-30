import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    @State private var servings = 0
    @State private var isEditing = false
    @State private var checkedIngredients: Set<Int> = []

    var body: some View {
        List {
            if !recipe.summary.isEmpty {
                Section { Text(recipe.summary) }
            }

            Section {
                HStack {
                    TimeView(title: "Prep", minutes: recipe.prepMinutes)
                    TimeView(title: "Cook", minutes: recipe.cookMinutes)
                    TimeView(title: "Total", minutes: recipe.totalMinutes)
                }
            }

            Section {
                Stepper("^[\(servings) serving](inflect: true)", value: $servings, in: 1...50)
                ForEach(Array(recipe.ingredients(forServings: servings).enumerated()), id: \.offset) { index, line in
                    Button {
                        checkedIngredients.formSymmetricDifference([index])
                    } label: {
                        Label {
                            Text(line).strikethrough(checkedIngredients.contains(index))
                        } icon: {
                            Image(systemName: checkedIngredients.contains(index) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Ingredients")
            } footer: {
                if servings != recipe.servings {
                    Text("Scaled from \(recipe.servings) servings.")
                }
            }

            if !recipe.steps.isEmpty {
                Section("Steps") {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color.accentColor)
                            Text(step)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(recipe.isFavorite ? "Unfavorite" : "Favorite", systemImage: recipe.isFavorite ? "heart.fill" : "heart") {
                    recipe.isFavorite.toggle()
                }
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) { RecipeEditor(recipe: recipe) }
        .onAppear { if servings == 0 { servings = recipe.servings } }
        .onChange(of: recipe.servings) { _, new in servings = new }
    }
}

private struct TimeView: View {
    let title: LocalizedStringKey
    let minutes: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(minutes > 0 ? minutes.durationText : "–").font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
