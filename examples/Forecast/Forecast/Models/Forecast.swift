import Foundation

nonisolated struct Forecast: Sendable {
    struct Current: Sendable {
        let date: Date
        let temperature: Double
        let feelsLike: Double
        let humidity: Int
        let windSpeed: Double
        let code: Int
        let isDay: Bool
    }

    struct Hour: Identifiable, Sendable {
        let date: Date
        let temperature: Double
        let code: Int
        let isDay: Bool
        var id: Date { date }
    }

    struct Day: Identifiable, Sendable {
        let date: Date
        let code: Int
        let high: Double
        let low: Double
        let precipitationChance: Int?
        var id: Date { date }
    }

    let timeZone: TimeZone
    let current: Current
    let hours: [Hour]
    let days: [Day]

    /// The next `count` hours, starting with the current hour.
    func upcomingHours(from now: Date, count: Int = 24) -> [Hour] {
        Array(hours.filter { $0.date > now.addingTimeInterval(-3600) }.prefix(count))
    }

    /// Lowest low and highest high across all days, for drawing temperature bars.
    var temperatureRange: ClosedRange<Double> {
        let low = days.map(\.low).min() ?? 0
        let high = days.map(\.high).max() ?? 0
        return low...max(high, low + 1)
    }
}

// MARK: - Decoding the Open-Meteo response

nonisolated extension Forecast {
    // Explicit keys: `.convertFromSnakeCase` turns "temperature_2m" into
    // "temperature2M", which wouldn't match these property names.
    private struct Response: Decodable {
        let timezone: String
        let utcOffsetSeconds: Int
        let current: CurrentBlock
        let hourly: HourlyBlock
        let daily: DailyBlock

        enum CodingKeys: String, CodingKey {
            case timezone, current, hourly, daily
            case utcOffsetSeconds = "utc_offset_seconds"
        }

        struct CurrentBlock: Decodable {
            let time: String
            let temperature: Double
            let apparentTemperature: Double
            let humidity: Int
            let windSpeed: Double
            let weatherCode: Int
            let isDay: Int

            enum CodingKeys: String, CodingKey {
                case time
                case temperature = "temperature_2m"
                case apparentTemperature = "apparent_temperature"
                case humidity = "relative_humidity_2m"
                case windSpeed = "wind_speed_10m"
                case weatherCode = "weather_code"
                case isDay = "is_day"
            }
        }

        struct HourlyBlock: Decodable {
            let time: [String]
            let temperature: [Double?]
            let weatherCode: [Int?]
            let isDay: [Int?]

            enum CodingKeys: String, CodingKey {
                case time
                case temperature = "temperature_2m"
                case weatherCode = "weather_code"
                case isDay = "is_day"
            }
        }

        struct DailyBlock: Decodable {
            let time: [String]
            let weatherCode: [Int?]
            let high: [Double?]
            let low: [Double?]
            let precipitationChance: [Int?]

            enum CodingKeys: String, CodingKey {
                case time
                case weatherCode = "weather_code"
                case high = "temperature_2m_max"
                case low = "temperature_2m_min"
                case precipitationChance = "precipitation_probability_max"
            }
        }
    }

    struct DecodingFailure: Error {}

    /// Decodes a forecast. Times in the response are local to the place, so
    /// they're parsed using the place's time zone.
    static func decode(_ data: Data) throws -> Forecast {
        let r = try JSONDecoder().decode(Response.self, from: data)

        let timeZone = TimeZone(identifier: r.timezone) ?? TimeZone(secondsFromGMT: r.utcOffsetSeconds) ?? .gmt
        let dateTime = formatter("yyyy-MM-dd'T'HH:mm", timeZone)
        let dateOnly = formatter("yyyy-MM-dd", timeZone)
        guard let now = dateTime.date(from: r.current.time) else { throw DecodingFailure() }

        let current = Current(
            date: now,
            temperature: r.current.temperature,
            feelsLike: r.current.apparentTemperature,
            humidity: r.current.humidity,
            windSpeed: r.current.windSpeed,
            code: r.current.weatherCode,
            isDay: r.current.isDay == 1
        )

        // Skip any hour or day with missing values rather than failing the whole forecast.
        let hours = r.hourly.time.indices.compactMap { i -> Hour? in
            guard let date = dateTime.date(from: r.hourly.time[i]),
                let temperature = r.hourly.temperature[safe: i] ?? nil,
                let code = r.hourly.weatherCode[safe: i] ?? nil
            else { return nil }
            return Hour(date: date, temperature: temperature, code: code, isDay: (r.hourly.isDay[safe: i] ?? nil) != 0)
        }

        let days = r.daily.time.indices.compactMap { i -> Day? in
            guard let date = dateOnly.date(from: r.daily.time[i]),
                let code = r.daily.weatherCode[safe: i] ?? nil,
                let high = r.daily.high[safe: i] ?? nil,
                let low = r.daily.low[safe: i] ?? nil
            else { return nil }
            return Day(date: date, code: code, high: high, low: low, precipitationChance: r.daily.precipitationChance[safe: i] ?? nil)
        }

        return Forecast(timeZone: timeZone, current: current, hours: hours, days: days)
    }

    private static func formatter(_ format: String, _ timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }
}

extension Array {
    nonisolated subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
