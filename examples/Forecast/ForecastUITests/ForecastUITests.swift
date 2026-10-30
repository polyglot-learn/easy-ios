import XCTest

final class ForecastUITests: XCTestCase {
    /// Runs against canned data (the app uses `WeatherService.sample` under -ui-testing).
    @MainActor
    func testSearchSaveAndOpenCity() {
        let app = XCUIApplication()
        // en_GB shows weather in Celsius, matching the canned 16 °C.
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.launch()

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), "search field")
        search.tap()
        search.typeText("Lisbon")

        let add = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add Lisbon, Lisbon District")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5), "search result")
        add.tap()

        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Lisbon")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "saved city row")
        row.tap()

        XCTAssertTrue(app.staticTexts["Mainly clear"].waitForExistence(timeout: 5), "conditions")
        XCTAssertTrue(app.staticTexts["16°C"].exists, "temperature")
    }
}
