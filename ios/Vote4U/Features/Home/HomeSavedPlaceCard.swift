import SwiftUI

struct HomeSavedPlaceCard: View {
    let place: SavedPlace
    let onOpenVote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Saved for offline", systemImage: "bookmark.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.tint)
                    Text(place.name)
                        .font(.title3.bold())
                    Text(place.addr)
                        .font(.subheadline)
                        .foregroundStyle(Vote4UTheme.supportingText)
                }

                Spacer(minLength: 12)

                Label("Offline", systemImage: "internaldrive")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Available offline")
            }

            if place.type != nil {
                Text(place.displayType)
                    .font(.subheadline)
            }

            Text(place.confirmationNotice)
                .font(.subheadline)
                .accessibilityIdentifier("saved-place-confirmation")

            Link("Check official polling place", destination: URL(string: "https://www.usa.gov/find-polling-place")!)
                .font(.subheadline)
                .padding(.vertical, 8)

            HStack(spacing: 10) {
                Button(action: openDirections) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Vote4UTheme.actionBlue)

                Button(action: onOpenVote) {
                    Label("View", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
    }

    private func openDirections() {
        MapDirections.open(
            name: place.name,
            address: place.addr,
            latitude: place.lat,
            longitude: place.lng
        )
    }
}
