import MapKit
import SwiftUI

struct PollingLocationCard: View {
    let location: PollingLocation
    var isSaved: Bool = false
    var onSave: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(location.name)
                    .font(.headline)
                Spacer(minLength: 8)
                if let miles = location.milesAway {
                    Text(miles)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Text(location.addr)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text(location.type)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: .capsule)

                // The single most important rule in this codebase: never present an unofficial
                // venue as confirmed.
                if !location.isConfirmed {
                    Label("Not confirmed", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 8) {
                Button {
                    openDirections()
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)

                Button {
                    onSave()
                } label: {
                    Label(
                        isSaved ? "Saved" : "Save",
                        systemImage: isSaved ? "bookmark.fill" : "bookmark"
                    )
                    .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .disabled(isSaved)

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 2)
            .sensoryFeedback(.success, trigger: isSaved)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 12))
    }

    private var shareText: String {
        "\(location.name)\n\(location.addr)"
    }

    /// Apple Maps via MapKit rather than a maps.apple.com URL: it is first-party, free, and needs
    /// no key or network round trip.
    private func openDirections() {
        let item: MKMapItem
        if let lat = location.lat, let lng = location.lng {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        } else {
            // No coordinates from the upstream data — hand Apple Maps the address to resolve
            // rather than inventing a pin.
            item = MKMapItem(placemark: MKPlacemark(coordinate: kCLLocationCoordinate2DInvalid))
        }
        item.name = location.name
        if location.lat != nil {
            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } else if let url = URL(string: "http://maps.apple.com/?address=\(location.addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
}
