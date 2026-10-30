import XCTest

final class HeadlinesUITests: XCTestCase {
    /// Runs against canned stories (the app uses `HNClient.sample` under -ui-testing).
    @MainActor
    func testSaveStoryAndFindItInSaved() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let title = "SQLite is not a toy database"
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))

        row.swipeLeft()
        app.buttons["Save"].tap()

        app.tabBars.buttons["Saved"].tap()
        let saved = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
    }
}
