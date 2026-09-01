import Foundation
import CoreLocation

protocol LocationService: AnyObject {
    var currentLocation: Location? { get }
    var onLocationUpdate: ((Location) -> Void)? { get set }
    func requestPermission()
    func startUpdating()
}

final class CoreLocationService: NSObject, LocationService, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var currentLocation: Location?
    var onLocationUpdate: ((Location) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let location = Location(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, city: nil, region: nil)
        currentLocation = location
        onLocationUpdate?(location)
    }
}

/// Defaults to the demo user's Bay Area location so the swipe deck has something to sort
/// by distance without requiring a real permission prompt in the simulator/mock mode.
final class MockLocationService: LocationService {
    var currentLocation: Location?
    var onLocationUpdate: ((Location) -> Void)?

    init(currentLocation: Location? = MockSeedData.demoUser.location) {
        self.currentLocation = currentLocation
    }

    func requestPermission() {}

    func startUpdating() {
        if let currentLocation {
            onLocationUpdate?(currentLocation)
        }
    }
}
