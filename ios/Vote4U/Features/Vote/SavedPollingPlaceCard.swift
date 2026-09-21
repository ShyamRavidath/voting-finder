import SwiftUI

struct SavedPollingPlaceCard: View {
    let place: SavedPlace
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your saved polling place", systemImage: "bookmark.fill")
                .font(.caption.bold())
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                Text(place.addr)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button(action: openDirections) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Remove", systemImage: "trash", role: .destructive, action: onRemove)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.accentColor.opacity(0.1), in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
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
