import XCTest

final class RecipesUITests: XCTestCase {
    @MainActor
    func testAddRecipeAndScaleServings() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["Add Recipe"].tap()
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Rice")

        let ingredients = app.textFields["Ingredients"]
        ingredients.tap()
        ingredients.typeText("1 cup rice")
        app.buttons["Save"].tap()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Rice")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["1 cup rice"].waitForExistence(timeout: 5))

        // Default is 2 servings; going to 3 scales 1 cup to 1½.
        app.steppers.firstMatch.buttons["Increment"].tap()
        XCTAssertTrue(app.staticTexts["1½ cup rice"].waitForExistence(timeout: 5))
    }
}
