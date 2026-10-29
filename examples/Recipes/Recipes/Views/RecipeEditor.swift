import SwiftData
import SwiftUI

/// Adds a new recipe when `recipe` is nil, otherwise edits it.
struct RecipeEditor: View {
    let recipe: Recipe?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var summary = ""
    @State private var servings = 2
    @State private var prepMinutes = 0
    @State private var cookMinutes = 0
    @State private var ingredientsText = ""
    @State private var stepsText = ""

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Short description", text: $summary, axis: .vertical)
                }
                Section {
                    Stepper("^[\(servings) serving](inflect: true)", value: $servings, in: 1...50)
                    Stepper("Prep: \(prepMinutes) min", value: $prepMinutes, in: 0...600, step: 5)
                    Stepper("Cook: \(cookMinutes) min", value: $cookMinutes, in: 0...600, step: 5)
                }
                Section {
                    TextField("Ingredients", text: $ingredientsText, axis: .vertical)
                        .lineLimit(4...)
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("One per line. Start with the amount, like “1 1/2 cups flour”, so it can be scaled.")
                }
                Section {
                    TextField("Steps", text: $stepsText, axis: .vertical)
                        .lineLimit(4...)
                } header: {
                    Text("Steps")
                } footer: {
                    Text("One step per line.")
                }
            }
            .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(trimmedName.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func lines(_ text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func load() {
        guard let recipe else { return }
        name = recipe.name
        summary = recipe.summary
        servings = recipe.servings
        prepMinutes = recipe.prepMinutes
        cookMinutes = recipe.cookMinutes
        ingredientsText = recipe.ingredients.joined(separator: "\n")
        stepsText = recipe.steps.joined(separator: "\n")
    }

    private func save() {
        let target = recipe ?? Recipe(name: trimmedName)
        target.name = trimmedName
        target.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        target.servings = servings
        target.prepMinutes = prepMinutes
        target.cookMinutes = cookMinutes
        target.ingredients = lines(ingredientsText)
        target.steps = lines(stepsText)
        if recipe == nil { context.insert(target) }
        dismiss()
    }
}
