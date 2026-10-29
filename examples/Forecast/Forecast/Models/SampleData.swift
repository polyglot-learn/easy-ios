import Foundation

/// Canned API responses for previews and UI tests, shaped like real Open-Meteo output.
nonisolated enum SampleData {
    static let searchJSON = Data(
        """
        {"results":[
          {"id":2267057,"name":"Lisbon","latitude":38.72509,"longitude":-9.1498,"country":"Portugal","admin1":"Lisbon District","timezone":"Europe/Lisbon"},
          {"id":5160951,"name":"Lisbon","latitude":40.772,"longitude":-80.76813,"country":"United States","admin1":"Ohio","timezone":"America/New_York"}
        ]}
        """.utf8)

    /// A forecast starting at the current hour (UTC) so "upcoming" views have data.
    static func forecastJSON(now: Date = .now) -> Data {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let hourStart = calendar.dateInterval(of: .hour, for: now)!.start
        let dayStart = calendar.startOfDay(for: now)

        let hourFormat = Date.ISO8601FormatStyle(timeZone: .gmt).year().month().day().dateTimeSeparator(.standard).time(
            includingFractionalSeconds: false)
        func hourString(_ date: Date) -> String { String(date.formatted(hourFormat).prefix(16)) }
        func dayString(_ date: Date) -> String { String(hourString(date).prefix(10)) }

        let hours = (0..<48).map { calendar.date(byAdding: .hour, value: $0 - 2, to: hourStart)! }
        let temps = hours.indices.map { 14 + 6 * sin(Double($0) / 24 * 2 * .pi) }
        let days = (0..<7).map { calendar.date(byAdding: .day, value: $0, to: dayStart)! }

        let json = """
            {"timezone":"GMT","utc_offset_seconds":0,
             "current":{"time":"\(hourString(hourStart))","temperature_2m":16.0,"apparent_temperature":15.5,
                        "relative_humidity_2m":71,"weather_code":1,"wind_speed_10m":4.7,"is_day":1},
             "hourly":{"time":[\(hours.map { "\"\(hourString($0))\"" }.joined(separator: ","))],
                       "temperature_2m":[\(temps.map { String(format: "%.1f", $0) }.joined(separator: ","))],
                       "weather_code":[\(hours.indices.map { String([0, 1, 2, 3, 61][$0 % 5]) }.joined(separator: ","))],
                       "is_day":[\(hours.map { String((6..<19).contains(calendar.component(.hour, from: $0)) ? 1 : 0) }.joined(separator: ","))]},
             "daily":{"time":[\(days.map { "\"\(dayString($0))\"" }.joined(separator: ","))],
                      "weather_code":[1,3,61,80,0,2,95],
                      "temperature_2m_max":[25.8,26.3,19.0,17.5,22.1,24.0,20.2],
                      "temperature_2m_min":[12.4,14.4,11.0,9.8,10.5,13.0,12.1],
                      "precipitation_probability_max":[0,5,80,60,null,10,70]}}
            """
        return Data(json.utf8)
    }
}
