import SwiftUI

struct PlaceView: View {
    let place: SavedPlace
    @Environment(ForecastStore.self) private var store

    var body: some View {
        Group {
            switch store.state(for: place.coordinate) {
            case .loading:
                ProgressView("Loading forecast…")
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't Load Forecast", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await store.load(place.coordinate, force: true) } }
                }
            case .loaded(let forecast):
                ForecastList(forecast: forecast)
                    .refreshable { await store.load(place.coordinate, force: true) }
            }
        }
        .navigationTitle(place.name)
        .task { await store.load(place.coordinate) }
    }
}

private struct ForecastList: View {
    let forecast: Forecast

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Image(systemName: WeatherCode.symbol(forecast.current.code, isDay: forecast.current.isDay))
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 56))
                    Text(Format.temperature(forecast.current.temperature))
                        .font(.system(size: 64, weight: .thin).monospacedDigit())
                    Text(WeatherCode.description(forecast.current.code))
                        .font(.title3)
                    HStack(spacing: 16) {
                        Label("Feels \(Format.temperature(forecast.current.feelsLike))", systemImage: "thermometer.medium")
                        Label("\(forecast.current.humidity)%", systemImage: "humidity")
                        Label(Format.wind(forecast.current.windSpeed), systemImage: "wind")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Next 24 hours") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(forecast.upcomingHours(from: .now)) { hour in
                            VStack(spacing: 8) {
                                Text(hour.date.formatted(Date.FormatStyle(timeZone: forecast.timeZone).hour()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: WeatherCode.symbol(hour.code, isDay: hour.isDay))
                                    .symbolRenderingMode(.multicolor)
                                    .frame(height: 24)
                                Text(Format.temperature(hour.temperature))
                                    .font(.subheadline.monospacedDigit())
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("7-day forecast") {
                ForEach(forecast.days) { day in
                    DayRow(day: day, range: forecast.temperatureRange, timeZone: forecast.timeZone)
                }
            }

            Section {
                Link("Weather data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com/")!)
                    .font(.footnote)
            }
        }
    }
}

private struct DayRow: View {
    let day: Forecast.Day
    let range: ClosedRange<Double>
    let timeZone: TimeZone

    var body: some View {
        HStack(spacing: 12) {
            Text(day.date.formatted(Date.FormatStyle(timeZone: timeZone).weekday(.abbreviated)))
                .frame(width: 44, alignment: .leading)
            Image(systemName: WeatherCode.symbol(day.code))
                .symbolRenderingMode(.multicolor)
                .frame(width: 28)
                .accessibilityLabel(WeatherCode.description(day.code))
            Text(day.precipitationChance.map { $0 >= 20 ? "\($0)%" : "" } ?? "")
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 36)
            Text(Format.temperature(day.low))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
            TemperatureBar(low: day.low, high: day.high, range: range)
            Text(Format.temperature(day.high))
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}

private struct TemperatureBar: View {
    let low: Double
    let high: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geometry in
            let span = range.upperBound - range.lowerBound
            let start = (low - range.lowerBound) / span
            let end = (high - range.lowerBound) / span
            Capsule()
                .fill(Color.secondary.opacity(0.2))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [.teal, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, geometry.size.width * (end - start)))
                        .offset(x: geometry.size.width * start)
                }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}
