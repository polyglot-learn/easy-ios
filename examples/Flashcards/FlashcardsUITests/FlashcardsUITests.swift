import XCTest

final class FlashcardsUITests: XCTestCase {
    @MainActor
    func testCreateDeckAddCardAndStudy() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["New Deck"].tap()
        let nameField = app.alerts.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.typeText("Capitals")
        app.alerts.buttons["Create"].tap()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Capitals")).firstMatch.tap()
        app.buttons["Add Card"].tap()

        let question = app.textFields["Question"]
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        question.tap()
        question.typeText("Capital of France?")
        let answer = app.textFields["Answer"]
        answer.tap()
        answer.typeText("Paris")
        app.buttons["Save"].tap()

        app.buttons["Study 1 due"].tap()
        app.buttons["Show Answer"].tap()
        XCTAssertTrue(app.staticTexts["Paris"].waitForExistence(timeout: 5))
        app.buttons["Got It"].tap()

        XCTAssertTrue(app.staticTexts["All Done"].waitForExistence(timeout: 5))
        app.buttons["Finish"].tap()
        XCTAssertTrue(app.buttons["Nothing to review"].waitForExistence(timeout: 5))
    }
}
