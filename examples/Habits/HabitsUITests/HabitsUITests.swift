import XCTest

final class HabitsUITests: XCTestCase {
    @MainActor
    func testAddHabitAndCheckInToday() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["Add Habit"].tap()
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Meditate")
        app.buttons["Save"].tap()

        let checkIn = app.buttons["Mark Meditate done today"]
        XCTAssertTrue(checkIn.waitForExistence(timeout: 5))
        checkIn.tap()

        XCTAssertTrue(app.buttons["Undo Meditate today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 day streak"].exists)
    }
}
