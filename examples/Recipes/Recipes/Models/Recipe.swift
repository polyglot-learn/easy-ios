import Foundation
import SwiftData

@Model
final class Recipe {
    var name: String
    var summary: String
    var servings: Int
    var prepMinutes: Int
    var cookMinutes: Int
    /// One ingredient per line, e.g. "1 1/2 cups flour".
    var ingredients: [String]
    var steps: [String]
    var isFavorite: Bool
    var createdAt: Date

    init(
        name: String,
        summary: String = "",
        servings: Int = 2,
        prepMinutes: Int = 0,
        cookMinutes: Int = 0,
        ingredients: [String] = [],
        steps: [String] = [],
        createdAt: Date = .now
    ) {
        self.name = name
        self.summary = summary
        self.servings = servings
        self.prepMinutes = prepMinutes
        self.cookMinutes = cookMinutes
        self.ingredients = ingredients
        self.steps = steps
        self.isFavorite = false
        self.createdAt = createdAt
    }

    var totalMinutes: Int { prepMinutes + cookMinutes }

    /// Ingredients with quantities scaled for a different number of servings.
    func ingredients(forServings target: Int, locale: Locale = .current) -> [String] {
        guard servings > 0, target > 0 else { return ingredients }
        let factor = Double(target) / Double(servings)
        return ingredients.map { IngredientScaler.scale($0, by: factor, locale: locale) }
    }
}

extension Int {
    /// "45 min" or "1 hr 15 min".
    var durationText: String {
        Duration.seconds(self * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}
