import Foundation
import SwiftData

/// A city the user saved to their list.
@Model
final class SavedPlace {
    var name: String
    var region: String
    var country: String
    var latitude: Double
    var longitude: Double
    var addedAt: Date

    init(_ result: PlaceResult, addedAt: Date = .now) {
        name = result.name
        region = result.admin1 ?? ""
        country = result.country ?? ""
        latitude = result.latitude
        longitude = result.longitude
        self.addedAt = addedAt
    }

    var subtitle: String {
        [region, country].filter { !$0.isEmpty && $0 != name }.joined(separator: ", ")
    }

    var coordinate: Coordinate { Coordinate(latitude: latitude, longitude: longitude) }
}

nonisolated struct Coordinate: Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}

/// A city returned by the geocoding search.
nonisolated struct PlaceResult: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?

    var subtitle: String {
        [admin1, country].compactMap { $0 }.filter { !$0.isEmpty && $0 != name }.joined(separator: ", ")
    }

    var coordinate: Coordinate { Coordinate(latitude: latitude, longitude: longitude) }
}
