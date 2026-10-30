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

        // A tap during the mood button's animation can miss, so wait for focus and tap again if needed.
        let text = app.textFields["Write something…"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.tap()
        let focused = expectation(for: NSPredicate(format: "hasKeyboardFocus == true"), evaluatedWith: text)
        if XCTWaiter.wait(for: [focused], timeout: 3) != .completed {
            text.tap()
        }
        text.typeText("Finished my first marathon")
        app.buttons["Save"].tap()

        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Finished my first marathon")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 day"].exists, "Writing streak should be 1 day")
    }
}
