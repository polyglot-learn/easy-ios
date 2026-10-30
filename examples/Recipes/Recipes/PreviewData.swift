import Foundation
import SwiftData

enum PreviewData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(for: Recipe.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let pancakes = Recipe(
            name: "Fluffy Pancakes",
            summary: "A weekend breakfast classic.",
            servings: 4,
            prepMinutes: 10,
            cookMinutes: 15,
            ingredients: ["1 1/2 cups flour", "3 1/2 tsp baking powder", "1 tbsp sugar", "1 1/4 cups milk", "1 egg", "Salt to taste"],
            steps: [
                "Whisk the dry ingredients.", "Add milk and egg; stir until just combined.",
                "Cook on a hot buttered pan until bubbles form, then flip.",
            ]
        )
        pancakes.isFavorite = true
        container.mainContext.insert(pancakes)
        container.mainContext.insert(
            Recipe(name: "Tomato Soup", servings: 2, prepMinutes: 5, cookMinutes: 25, ingredients: ["800 g tomatoes", "1 onion"]))
        return container
    }()
}
