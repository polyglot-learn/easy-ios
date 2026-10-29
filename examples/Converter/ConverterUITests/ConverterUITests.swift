import XCTest

final class ConverterUITests: XCTestCase {
    @MainActor
    func testConvertAndSwap() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLocale", "en_US"]
        app.launch()

        // Starts at 1 kilometer → miles. Replace "1" with "10".
        let input = app.textFields["input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText(XCUIKeyboardKey.delete.rawValue + "10")

        let result = app.staticTexts["result"]
        XCTAssertEqual(result.label, "6.21371")

        app.buttons["Swap Units"].tap()
        XCTAssertEqual(input.value as? String, "6.21371")
        XCTAssertEqual(result.label, "10")
    }
}
