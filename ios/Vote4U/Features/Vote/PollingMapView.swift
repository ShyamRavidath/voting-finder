import MapKit
import SwiftUI

/// MapKit, not OpenStreetMap tiles. OSM's tile usage policy discourages app traffic, and Apple
/// Maps is first-party, free and keyless on iOS.
struct PollingMapView: View {
    let locations: [PollingLocation]

    private var pins: [PollingLocation] {
        locations.filter { $0.lat != nil && $0.lng != nil }
    }

    var body: some View {
        if pins.isEmpty {
            EmptyView()
        } else {
            Map(initialPosition: .region(region)) {
                ForEach(pins) { location in
                    if let lat = location.lat, let lng = location.lng {
                        Marker(
                            location.name,
                            systemImage: location.isConfirmed ? "checkmark.circle.fill" : "mappin",
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                        )
                    }
                }
            }
            .frame(height: 220)
            .clipShape(.rect(cornerRadius: 12))
            .accessibilityLabel("Map of \(pins.count) polling locations")
        }
    }

    private var region: MKCoordinateRegion {
        let lats = pins.compactMap(\.lat)
        let lngs = pins.compactMap(\.lng)
        guard let minLat = lats.min(), let maxLat = lats.max(),
            let minLng = lngs.min(), let maxLng = lngs.max()
        else {
            return MKCoordinateRegion()
        }

        // Pad the span so edge pins are not flush against the frame, with a floor for the
        // single-pin case where the computed span would be zero.
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.4, 0.02),
                longitudeDelta: max((maxLng - minLng) * 1.4, 0.02)
            )
        )
    }
}
