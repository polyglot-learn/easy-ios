import XCTest

final class BudgetUITests: XCTestCase {
    @MainActor
    func testAddExpenseUpdatesMonthTotal() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Add Expense"].tap()
        let amount = app.textFields["Amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap()
        amount.typeText("42.50")

        let title = app.textFields["What was it for?"]
        title.tap()
        title.typeText("Groceries")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Groceries"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["monthTotal"].label, "$42.50")
    }
}
