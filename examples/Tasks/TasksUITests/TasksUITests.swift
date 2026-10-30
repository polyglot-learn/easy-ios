import XCTest

final class TasksUITests: XCTestCase {
    @MainActor
    func testAddCompleteAndFindTask() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["Add Task"].tap()
        let title = app.textFields["Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Water the plants")
        app.buttons["Save"].tap()

        // The row is a button, so its title is part of the button's label.
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Water the plants")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))

        app.buttons["Mark Water the plants as done"].tap()
        XCTAssertTrue(row.waitForNonExistence(timeout: 5))

        app.buttons["Completed"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Mark Water the plants as not done"].exists)
    }
}
