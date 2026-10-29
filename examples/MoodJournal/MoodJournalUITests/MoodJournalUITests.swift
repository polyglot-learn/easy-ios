import XCTest

final class MoodJournalUITests: XCTestCase {
    @MainActor
    func testWriteEntryWithMood() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["New Entry"].tap()
        let great = app.buttons["Great"]
        XCTAssertTrue(great.waitForExistence(timeout: 5))
        great.tap()

        let text = app.textFields["Write something…"]
        text.tap()
        text.typeText("Finished my first marathon")
        app.buttons["Save"].tap()

        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Finished my first marathon")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 day"].exists, "Writing streak should be 1 day")
    }
}
