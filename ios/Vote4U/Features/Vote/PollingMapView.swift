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
                    Marker(
                        location.name,
                        systemImage: location.isConfirmed ? "checkmark.circle.fill" : "mappin",
                        coordinate: CLLocationCoordinate2D(latitude: location.lat!, longitude: location.lng!)
                    )
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
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lngs.min()! + lngs.max()!) / 2
        )
        // Pad the span so edge pins are not flush against the frame, with a floor for the
        // single-pin case where the computed span would be zero.
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.4, 0.02),
            longitudeDelta: max((lngs.max()! - lngs.min()!) * 1.4, 0.02)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
