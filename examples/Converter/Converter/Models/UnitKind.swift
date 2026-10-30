import Foundation

enum UnitKind: String, CaseIterable, Identifiable {
    case length, mass, temperature, volume, speed, area

    var id: Self { self }

    var title: String {
        switch self {
        case .length: String(localized: "Length")
        case .mass: String(localized: "Weight")
        case .temperature: String(localized: "Temperature")
        case .volume: String(localized: "Volume")
        case .speed: String(localized: "Speed")
        case .area: String(localized: "Area")
        }
    }

    var symbol: String {
        switch self {
        case .length: "ruler"
        case .mass: "scalemass"
        case .temperature: "thermometer.medium"
        case .volume: "drop"
        case .speed: "speedometer"
        case .area: "square.dashed"
        }
    }

    var units: [Dimension] {
        switch self {
        case .length:
            [.kilometers, .meters, .centimeters, .millimeters, .miles, .yards, .feet, .inches, .nauticalMiles] as [UnitLength]
        case .mass:
            [.kilograms, .grams, .milligrams, .metricTons, .pounds, .ounces, .stones] as [UnitMass]
        case .temperature:
            [.celsius, .fahrenheit, .kelvin] as [UnitTemperature]
        case .volume:
            [.liters, .milliliters, .cubicMeters, .gallons, .quarts, .pints, .cups, .fluidOunces, .tablespoons, .teaspoons] as [UnitVolume]
        case .speed:
            [.kilometersPerHour, .milesPerHour, .metersPerSecond, .knots] as [UnitSpeed]
        case .area:
            [.squareMeters, .squareKilometers, .hectares, .squareFeet, .squareMiles, .acres] as [UnitArea]
        }
    }

    /// Sensible starting pair, e.g. kilometers → miles.
    var defaultPair: (from: Int, to: Int) {
        switch self {
        case .length: (0, 4)
        case .mass: (0, 4)
        case .temperature: (0, 1)
        case .volume: (0, 3)
        case .speed: (0, 1)
        case .area: (0, 3)
        }
    }
}
