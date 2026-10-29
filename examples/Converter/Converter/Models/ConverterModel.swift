import Foundation
import Observation

/// The converter's state. Choices are remembered between launches.
@Observable
final class ConverterModel {
    var kind: UnitKind {
        didSet {
            guard kind != oldValue else { return }
            (fromIndex, toIndex) = kind.defaultPair
            save()
        }
    }
    var fromIndex: Int { didSet { save() } }
    var toIndex: Int { didSet { save() } }
    var input: String

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored var locale: Locale = .current

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let kind = UnitKind(rawValue: defaults.string(forKey: "kind") ?? "") ?? .length
        self.kind = kind
        let count = kind.units.count
        let from = defaults.object(forKey: "from") as? Int ?? kind.defaultPair.from
        let to = defaults.object(forKey: "to") as? Int ?? kind.defaultPair.to
        self.fromIndex = (0..<count).contains(from) ? from : kind.defaultPair.from
        self.toIndex = (0..<count).contains(to) ? to : kind.defaultPair.to
        self.input = "1"
    }

    var fromUnit: Dimension { kind.units[fromIndex] }
    var toUnit: Dimension { kind.units[toIndex] }

    /// The typed value, accepting the locale's decimal separator or a period.
    var value: Double? {
        let text = input.trimmingCharacters(in: .whitespaces)
        if let number = Double(text) { return number }
        let separator = locale.decimalSeparator ?? "."
        return Double(text.replacingOccurrences(of: separator, with: "."))
    }

    var result: Double? {
        value.map { convert($0, to: toUnit) }
    }

    func convert(_ value: Double, to unit: Dimension) -> Double {
        Measurement(value: value, unit: fromUnit).converted(to: unit).value
    }

    /// Reverses the conversion: the current result becomes the new input.
    func swap() {
        let previousResult = result
        (fromIndex, toIndex) = (toIndex, fromIndex)
        if let previousResult { input = Self.format(previousResult, locale: locale) }
    }

    /// Up to 6 significant digits, without scientific notation for everyday values.
    static func format(_ value: Double, locale: Locale = .current) -> String {
        value.formatted(.number.precision(.significantDigits(1...6)).locale(locale))
    }

    static func name(of unit: Dimension, locale: Locale = .current) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .long
        return formatter.string(from: unit).localizedCapitalized
    }

    static func symbol(of unit: Dimension, locale: Locale = .current) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .short
        return formatter.string(from: unit)
    }

    private func save() {
        defaults.set(kind.rawValue, forKey: "kind")
        defaults.set(fromIndex, forKey: "from")
        defaults.set(toIndex, forKey: "to")
    }
}
