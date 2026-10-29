import Foundation

/// Values from the API are metric; these format them in the user's preferred units.
enum Format {
    static func temperature(_ celsius: Double) -> String {
        Measurement(value: celsius, unit: UnitTemperature.celsius)
            .formatted(.measurement(width: .narrow, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    static func wind(_ kilometersPerHour: Double) -> String {
        Measurement(value: kilometersPerHour, unit: UnitSpeed.kilometersPerHour)
            .formatted(.measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(0))))
    }
}
