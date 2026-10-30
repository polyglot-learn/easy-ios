import Foundation
import Testing

@testable import Forecast

@MainActor
struct ForecastDecodingTests {
    /// Trimmed from a real Open-Meteo response for Lisbon (UTC+1 in summer).
    let fixture = Data(
        """
        {"latitude":38.74,"longitude":-9.17,"utc_offset_seconds":3600,"timezone":"Europe/Lisbon",
         "current":{"time":"2027-07-01T15:00","interval":900,"temperature_2m":28.4,"apparent_temperature":29.1,
                    "relative_humidity_2m":40,"weather_code":0,"wind_speed_10m":12.2,"is_day":1},
         "hourly":{"time":["2027-07-01T14:00","2027-07-01T15:00","2027-07-01T16:00"],
                   "temperature_2m":[27.9,28.4,null],"weather_code":[0,1,2],"is_day":[1,1,1]},
         "daily":{"time":["2027-07-01","2027-07-02"],"weather_code":[0,61],
                  "temperature_2m_max":[30.1,24.0],"temperature_2m_min":[18.2,17.5],
                  "precipitation_probability_max":[0,null]}}
        """.utf8)

    @Test func decodesCurrentConditions() throws {
        let forecast = try Forecast.decode(fixture)
        #expect(forecast.current.temperature == 28.4)
        #expect(forecast.current.humidity == 40)
        #expect(forecast.current.isDay)
        #expect(forecast.timeZone.identifier == "Europe/Lisbon")
    }

    @Test func parsesLocalTimesInThePlacesTimeZone() throws {
        let forecast = try Forecast.decode(fixture)
        // 15:00 in Lisbon summer time is 14:00 UTC.
        #expect(forecast.current.date == Date(timeIntervalSince1970: 1_814_450_400))
    }

    @Test func skipsEntriesWithMissingValues() throws {
        let forecast = try Forecast.decode(fixture)
        #expect(forecast.hours.count == 2)
        #expect(forecast.days.count == 2)
        #expect(forecast.days[1].precipitationChance == nil)
    }

    @Test func upcomingHoursStartAtCurrentHour() throws {
        let forecast = try Forecast.decode(fixture)
        let now = forecast.current.date.addingTimeInterval(20 * 60)  // 15:20
        #expect(forecast.upcomingHours(from: now).map(\.temperature) == [28.4])
    }

    @Test func temperatureRangeSpansAllDays() throws {
        let forecast = try Forecast.decode(fixture)
        #expect(forecast.temperatureRange == 17.5...30.1)
    }

    @Test func malformedJSONThrows() {
        #expect(throws: (any Error).self) { try Forecast.decode(Data("{}".utf8)) }
    }

    @Test func sampleDataDecodes() throws {
        let forecast = try Forecast.decode(SampleData.forecastJSON())
        #expect(forecast.days.count == 7)
        #expect(forecast.upcomingHours(from: .now).count == 24)
    }
}

@MainActor
struct WeatherServiceTests {
    @Test func searchURLEncodesName() {
        let url = WeatherService.searchURL("São Paulo", language: "en")
        #expect(url.absoluteString.contains("name=S%C3%A3o%20Paulo"))
        #expect(url.host() == "geocoding-api.open-meteo.com")
    }

    @Test func forecastURLRequestsLocalTimezone() {
        let url = WeatherService.forecastURL(Coordinate(latitude: 52.52, longitude: 13.41))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(items.first { $0.name == "timezone" }?.value == "auto")
        #expect(items.first { $0.name == "latitude" }?.value == "52.52")
    }

    @Test func searchWithNoResultsReturnsEmpty() async throws {
        let service = WeatherService { _ in Data(#"{"generationtime_ms":0.1}"#.utf8) }
        #expect(try await service.search("zzzz").isEmpty)
    }

    @Test func storeCachesUntilForced() async {
        let counter = Counter()
        let service = WeatherService { _ in
            await counter.increment()
            return SampleData.forecastJSON()
        }
        let store = ForecastStore(service: service)
        let place = Coordinate(latitude: 1, longitude: 2)
        await store.load(place)
        await store.load(place)
        #expect(await counter.value == 1)
        await store.load(place, force: true)
        #expect(await counter.value == 2)
    }

    @Test func storeReportsFailures() async {
        let store = ForecastStore(service: WeatherService { _ in throw URLError(.notConnectedToInternet) })
        let place = Coordinate(latitude: 1, longitude: 2)
        await store.load(place)
        guard case .failed = store.state(for: place) else {
            Issue.record("expected a failure state")
            return
        }
    }

    @Test(arguments: [
        (0, true, "sun.max.fill"), (0, false, "moon.stars.fill"), (65, true, "cloud.heavyrain.fill"), (63, true, "cloud.rain.fill"),
        (1234, true, "questionmark.circle"),
    ])
    func weatherSymbols(code: Int, isDay: Bool, symbol: String) {
        #expect(WeatherCode.symbol(code, isDay: isDay) == symbol)
    }
}

private actor Counter {
    var value = 0
    func increment() { value += 1 }
}
