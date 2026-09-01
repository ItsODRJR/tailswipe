import Foundation
import CoreLocation

struct Location: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var city: String?
    var region: String?

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    func distanceMiles(from other: Location) -> Double {
        clLocation.distance(from: other.clLocation) / 1609.344
    }
}
