import Foundation
import Observation

/// Loads and caches forecasts so the list and detail screens share them.
@Observable
final class ForecastStore {
    enum State {
        case loading
        case loaded(Forecast)
        case failed(String)
    }

    private(set) var states: [Coordinate: State] = [:]
    @ObservationIgnored private var loadedAt: [Coordinate: Date] = [:]
    let service: WeatherService

    /// Forecasts younger than this aren't refetched unless forced.
    static let maxAge: TimeInterval = 15 * 60

    init(service: WeatherService) {
        self.service = service
    }

    func state(for coordinate: Coordinate) -> State {
        states[coordinate] ?? .loading
    }

    func load(_ coordinate: Coordinate, force: Bool = false, now: Date = .now) async {
        if !force, let last = loadedAt[coordinate], now.timeIntervalSince(last) < Self.maxAge,
            case .loaded = states[coordinate]
        {
            return
        }
        if states[coordinate] == nil { states[coordinate] = .loading }
        do {
            states[coordinate] = .loaded(try await service.forecast(for: coordinate))
            loadedAt[coordinate] = now
        } catch is CancellationError {
            // The view went away; keep whatever we had.
        } catch {
            states[coordinate] = .failed(error.localizedDescription)
        }
    }

    /// Refreshes several places in parallel.
    func loadAll(_ coordinates: [Coordinate], force: Bool = false) async {
        let service = service
        await withTaskGroup(of: (Coordinate, Forecast?, String?).self) { group in
            for coordinate in coordinates {
                group.addTask {
                    do {
                        return (coordinate, try await service.forecast(for: coordinate), nil)
                    } catch {
                        return (coordinate, nil, error.localizedDescription)
                    }
                }
            }
            for await (coordinate, forecast, message) in group {
                if let forecast {
                    states[coordinate] = .loaded(forecast)
                    loadedAt[coordinate] = .now
                } else if let message, !Task.isCancelled {
                    states[coordinate] = .failed(message)
                }
            }
        }
    }

    func search(_ name: String) async throws -> [PlaceResult] {
        try await service.search(name)
    }
}
