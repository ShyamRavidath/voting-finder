import SwiftUI

struct HomeSavedPlaceCard: View {
    let place: SavedPlace
    let onOpenVote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Your voting plan", systemImage: "bookmark.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.tint)
                    Text(place.name)
                        .font(.title3.bold())
                    Text(place.addr)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Label("Offline", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Available offline")
            }

            HStack(spacing: 10) {
                Button(action: openDirections) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

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
