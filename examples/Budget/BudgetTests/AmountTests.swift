import Foundation
import Testing

@testable import Budget

@MainActor
struct AmountTests {
    let us = Locale(identifier: "en_US")
    let germany = Locale(identifier: "de_DE")

    @Test(arguments: [("42.50", "42.5"), ("1,234.5", "1234.5"), (" 7 ", "7"), (".5", "0.5")])
    func parsesUSInput(text: String, expected: String) {
        #expect(Amount.parse(text, locale: us) == Decimal(string: expected))
    }

    @Test func parsesLocaleDecimalSeparator() {
        #expect(Amount.parse("42,50", locale: germany) == Decimal(string: "42.5"))
        #expect(Amount.parse("1.234,5", locale: germany) == Decimal(string: "1234.5"))
    }

    @Test(arguments: ["", "abc", "1.2.3", "-5", "$5"])
    func rejectsNonNumbers(text: String) {
        #expect(Amount.parse(text, locale: us) == nil)
    }

    @Test func editingTextRoundTrips() {
        let amount = Decimal(string: "1234.5")!
        #expect(Amount.editingText(amount, locale: us) == "1234.5")
        #expect(Amount.parse(Amount.editingText(amount, locale: germany), locale: germany) == amount)
    }
}
