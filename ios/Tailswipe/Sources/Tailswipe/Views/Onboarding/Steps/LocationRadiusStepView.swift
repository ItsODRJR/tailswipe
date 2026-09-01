import SwiftUI
import MapKit
import CoreLocation

/// Facebook Marketplace-style location step: a map centered on the user with a shaded
/// circle showing the current search radius, plus a slider to adjust it.
struct LocationRadiusStepView: View {
    @Binding var maxDistanceMiles: Double
    let locationService: LocationService

    @State private var camera: MapCameraPosition
    @State private var center: CLLocationCoordinate2D

    private static let fallback = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    init(maxDistanceMiles: Binding<Double>, locationService: LocationService) {
        _maxDistanceMiles = maxDistanceMiles
        self.locationService = locationService
        let initial = locationService.currentLocation.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        } ?? Self.fallback
        _center = State(initialValue: initial)
        _camera = State(initialValue: .region(
            MKCoordinateRegion(center: initial, latitudinalMeters: 60_000, longitudinalMeters: 60_000)
        ))
    }

    var body: some View {
        WizardStepScaffold(
            title: "Search radius",
            subtitle: "Only pets within this distance will show up in your deck."
        ) {
            VStack(spacing: 20) {
                Map(position: $camera) {
                    MapCircle(center: center, radius: milesToMeters(maxDistanceMiles))
                        .foregroundStyle(Color.accentColor.opacity(0.15))
                        .stroke(Color.accentColor, lineWidth: 2)
                    Marker("You", coordinate: center)
                }
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Within \(Int(maxDistanceMiles)) miles")
                        .font(.subheadline.weight(.medium))
                    Slider(value: $maxDistanceMiles, in: 1...200, step: 1)
                }

                Button {
                    useMyLocation()
                } label: {
                    Label("Use My Location", systemImage: "location.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            locationService.onLocationUpdate = { location in
                let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                center = coordinate
                camera = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 60_000, longitudinalMeters: 60_000))
            }
        }
    }

    private func useMyLocation() {
        locationService.requestPermission()
        locationService.startUpdating()
    }

    private func milesToMeters(_ miles: Double) -> Double {
        miles * 1609.34
    }
}
