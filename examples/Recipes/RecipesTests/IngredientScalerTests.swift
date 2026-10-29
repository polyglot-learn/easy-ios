import Foundation
import Testing

@testable import Recipes

@MainActor
struct IngredientScalerTests {
    let locale = Locale(identifier: "en_US")

    @Test(arguments: [
        ("2 eggs", 2.0, "eggs"),
        ("1/2 cup sugar", 0.5, "cup sugar"),
        ("1 1/2 cups flour", 1.5, "cups flour"),
        ("1½ cups milk", 1.5, "cups milk"),
        ("1 ½ cups milk", 1.5, "cups milk"),
        ("¾ tsp salt", 0.75, "tsp salt"),
        ("2.5 kg potatoes", 2.5, "kg potatoes"),
        ("2,5 kg potatoes", 2.5, "kg potatoes"),
        ("3", 3.0, ""),
    ])
    func parsesLeadingQuantities(line: String, quantity: Double, rest: String) throws {
        let parsed = try #require(IngredientScaler.parse(line))
        #expect(abs(parsed.quantity - quantity) < 0.0001)
        #expect(parsed.rest == rest)
    }

    @Test(arguments: ["Salt to taste", "", "a pinch of salt", "1/0 cup"])
    func linesWithoutQuantitiesAreNotParsed(line: String) {
        #expect(IngredientScaler.parse(line) == nil)
    }

    @Test(arguments: [
        (2.0, "2"),
        (0.5, "½"),
        (1.5, "1½"),
        (2.0 / 3, "⅔"),
        (3.25, "3¼"),
        (0.999, "1"),
        (1.4, "1.4"),
        (12.346, "12.35"),
    ])
    func formatsFriendlyAmounts(quantity: Double, expected: String) {
        #expect(IngredientScaler.format(quantity, locale: locale) == expected)
    }

    @Test func scalesLines() {
        #expect(IngredientScaler.scale("1 1/2 cups flour", by: 2, locale: locale) == "3 cups flour")
        #expect(IngredientScaler.scale("1 egg", by: 0.5, locale: locale) == "½ egg")
        #expect(IngredientScaler.scale("Salt to taste", by: 3, locale: locale) == "Salt to taste")
        #expect(IngredientScaler.scale("1/3 cup oil", by: 1, locale: locale) == "1/3 cup oil")
    }

    @Test func recipeScalesForServings() {
        let recipe = Recipe(name: "Test", servings: 4, ingredients: ["2 cups rice", "1 onion"])
        #expect(recipe.ingredients(forServings: 6, locale: locale) == ["3 cups rice", "1½ onion"])
        #expect(recipe.ingredients(forServings: 4, locale: locale) == ["2 cups rice", "1 onion"])
    }
}
