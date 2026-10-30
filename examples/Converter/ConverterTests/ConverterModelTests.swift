import Foundation
import Testing

@testable import Converter

@MainActor
struct ConverterModelTests {
    let english = Locale(identifier: "en_US")

    /// A fresh model backed by its own empty defaults.
    func makeModel() -> ConverterModel {
        let suite = "test-\(UUID().uuidString)"
        let model = ConverterModel(defaults: UserDefaults(suiteName: suite)!)
        model.locale = english
        return model
    }

    func index(of unit: Dimension, in kind: UnitKind) -> Int {
        kind.units.firstIndex(of: unit)!
    }

    @Test func defaultsToKilometersAndMiles() {
        let model = makeModel()
        #expect(model.kind == .length)
        #expect(model.fromUnit == UnitLength.kilometers)
        #expect(model.toUnit == UnitLength.miles)
    }

    @Test(arguments: [
        (UnitKind.temperature, UnitTemperature.celsius as Dimension, UnitTemperature.fahrenheit as Dimension, "100", 212.0),
        (.temperature, UnitTemperature.fahrenheit, UnitTemperature.celsius, "32", 0),
        (.length, UnitLength.miles, UnitLength.kilometers, "1", 1.609344),
        (.mass, UnitMass.kilograms, UnitMass.pounds, "1", 2.20462),
        (.speed, UnitSpeed.metersPerSecond, UnitSpeed.kilometersPerHour, "10", 36),
        (.area, UnitArea.hectares, UnitArea.squareMeters, "1", 10_000),
    ])
    func converts(kind: UnitKind, from: Dimension, to: Dimension, input: String, expected: Double) throws {
        let model = makeModel()
        model.kind = kind
        model.fromIndex = index(of: from, in: kind)
        model.toIndex = index(of: to, in: kind)
        model.input = input
        let result = try #require(model.result)
        #expect(abs(result - expected) < 0.001)
    }

    @Test func acceptsLocaleDecimalSeparator() {
        let model = makeModel()
        model.locale = Locale(identifier: "de_DE")
        model.input = "2,5"
        #expect(model.value == 2.5)
        model.input = "2.5"
        #expect(model.value == 2.5)
        model.input = "abc"
        #expect(model.value == nil && model.result == nil)
    }

    @Test func changingKindResetsUnits() {
        let model = makeModel()
        model.fromIndex = 3
        model.kind = .temperature
        #expect(model.fromUnit == UnitTemperature.celsius)
        #expect(model.toUnit == UnitTemperature.fahrenheit)
    }

    @Test func swapExchangesUnitsAndCarriesResult() {
        let model = makeModel()
        model.input = "10"
        model.swap()
        #expect(model.fromUnit == UnitLength.miles)
        #expect(model.toUnit == UnitLength.kilometers)
        #expect(model.input == "6.21371")
    }

    @Test func remembersChoices() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let first = ConverterModel(defaults: defaults)
        first.kind = .volume
        first.toIndex = 1
        let second = ConverterModel(defaults: defaults)
        #expect(second.kind == .volume)
        #expect(second.toIndex == 1)
    }

    @Test(arguments: [(1234.5678, "1,234.57"), (0.000123456, "0.000123456"), (5, "5")])
    func formatsWithSignificantDigits(value: Double, expected: String) {
        #expect(ConverterModel.format(value, locale: english) == expected)
    }
}
