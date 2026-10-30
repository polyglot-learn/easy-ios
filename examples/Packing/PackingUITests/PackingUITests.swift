import XCTest

final class PackingUITests: XCTestCase {
    @MainActor
    func testCreateTripWithSuggestionsAndPackItem() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["New Trip"].tap()
        let destination = app.textFields["Destination"]
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        destination.tap()
        destination.typeText("Tokyo")
        app.buttons["Create"].tap()

        // The row's label also includes the progress ring, so match anywhere in it.
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Tokyo")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let summary = app.staticTexts["packedSummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.hasPrefix("0 of "), summary.label)

        let wallet = app.buttons["Wallet"]
        XCTAssertTrue(wallet.waitForExistence(timeout: 5))
        wallet.tap()
        XCTAssertTrue(summary.label.hasPrefix("1 of "), summary.label)
        XCTAssertEqual(wallet.value as? String, "Packed")
    }
}
