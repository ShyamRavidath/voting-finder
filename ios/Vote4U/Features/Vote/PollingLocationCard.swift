import SwiftUI

struct PollingLocationCard: View {
    let location: PollingLocation
    var isSaved: Bool = false
    var onSave: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(location.name)
                    .font(.title3.bold())
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

            HStack(spacing: 10) {
                Text(location.type)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.thinMaterial, in: .capsule)

                // The single most important rule in this codebase: never present an unofficial
                // venue as confirmed.
                if !location.isConfirmed {
                    Label("Not confirmed", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Divider()

            Button {
                MapDirections.open(
                    name: location.name,
                    address: location.addr,
                    latitude: location.lat,
                    longitude: location.lng
                )
            } label: {
                Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .vote4UPrimaryActionStyle()

            HStack(spacing: 10) {
                Button(action: onSave) {
                    Label(
                        isSaved ? "Saved" : "Save",
                        systemImage: isSaved ? "bookmark.fill" : "bookmark"
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isSaved)

                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .sensoryFeedback(.success, trigger: isSaved)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [location.name, location.addr, location.type]
        if let miles = location.milesAway { parts.append("\(miles) away") }
        if !location.isConfirmed { parts.append("Not confirmed") }
        return parts.joined(separator: ", ")
    }

    private var shareText: String {
        "\(location.name)\n\(location.addr)"
    }

}
