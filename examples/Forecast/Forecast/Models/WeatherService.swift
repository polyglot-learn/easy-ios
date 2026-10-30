import Foundation

/// Talks to the free Open-Meteo API (no API key needed).
/// `fetch` is swappable so previews and UI tests can use canned data.
/// Nonisolated so requests and decoding run off the main actor.
nonisolated struct WeatherService: Sendable {
    var fetch: @Sendable (URL) async throws -> Data

    static let live = WeatherService { url in
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    static let sample = WeatherService { url in
        url.host()?.hasPrefix("geocoding") == true ? SampleData.searchJSON : SampleData.forecastJSON()
    }

    func search(_ name: String) async throws -> [PlaceResult] {
        struct Response: Decodable { let results: [PlaceResult]? }
        let data = try await fetch(Self.searchURL(name))
        return try JSONDecoder().decode(Response.self, from: data).results ?? []
    }

    func forecast(for coordinate: Coordinate) async throws -> Forecast {
        try Forecast.decode(await fetch(Self.forecastURL(coordinate)))
    }

    static func searchURL(_ name: String, language: String = Locale.current.language.languageCode?.identifier ?? "en") -> URL {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "format", value: "json"),
        ]
        return components.url!
    }

    static func forecastURL(_ coordinate: Coordinate) -> URL {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(
                name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code,is_day"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
        ]
        return components.url!
    }
}
