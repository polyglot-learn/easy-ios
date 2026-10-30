import Foundation

/// Descriptions and SF Symbols for WMO weather interpretation codes,
/// which Open-Meteo returns as `weather_code`.
nonisolated enum WeatherCode {
    static func description(_ code: Int) -> String {
        switch code {
        case 0: String(localized: "Clear")
        case 1: String(localized: "Mainly clear")
        case 2: String(localized: "Partly cloudy")
        case 3: String(localized: "Overcast")
        case 45, 48: String(localized: "Fog")
        case 51, 53, 55: String(localized: "Drizzle")
        case 56, 57: String(localized: "Freezing drizzle")
        case 61, 63: String(localized: "Rain")
        case 65: String(localized: "Heavy rain")
        case 66, 67: String(localized: "Freezing rain")
        case 71, 73, 75, 77: String(localized: "Snow")
        case 80, 81, 82: String(localized: "Rain showers")
        case 85, 86: String(localized: "Snow showers")
        case 95: String(localized: "Thunderstorm")
        case 96, 99: String(localized: "Thunderstorm with hail")
        default: String(localized: "Unknown")
        }
    }

    static func symbol(_ code: Int, isDay: Bool = true) -> String {
        switch code {
        case 0: isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: "cloud.fill"
        case 45, 48: "cloud.fog.fill"
        case 51...57: "cloud.drizzle.fill"
        case 65: "cloud.heavyrain.fill"
        case 61...67: "cloud.rain.fill"
        case 71...77, 85, 86: "cloud.snow.fill"
        case 80...82: isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case 95...99: "cloud.bolt.rain.fill"
        default: "questionmark.circle"
        }
    }
}
