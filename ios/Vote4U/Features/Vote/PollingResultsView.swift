import SwiftUI

struct PollingResultsView: View {
    let result: PollingResult
    let savedPlace: SavedPlace?
    let onSave: (PollingLocation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if result.isEmpty {
                ContentUnavailableView(
                    "No polling places found",
                    systemImage: "mappin.slash",
                    description: Text(
                        "We couldn’t confirm a polling place for this search. "
                            + "Use an official lookup below to find your assigned location and hours."
                    )
                )
            } else {
                resultSummary
                OfficialSourcesView()
                Text(result.isOfficial ? "Locations" : "Nearby buildings — not voting recommendations")
                    .font(.headline)
                if result.locations.contains(where: { $0.lat != nil && $0.lng != nil }) {
                    DisclosureGroup("View locations on map") {
                        PollingMapView(locations: result.locations)
                            .padding(.top, 10)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding()
                    .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
                }

                Text("Tap Save for offline to keep a location on Home.")
                    .font(.subheadline)
                    .foregroundStyle(Vote4UTheme.supportingText)

                ForEach(result.locations) { location in
                    PollingLocationCard(
                        location: location,
                        isSaved: isSaved(location),
                        onSave: { onSave(location) }
                    )
                }
            }

            if result.isEmpty {
                OfficialSourcesView()
            }
        }
    }

    private var resultSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let place = result.place {
                Label("Near \(place.city), \(place.stateAbbr)", systemImage: "location.fill")
                    .font(.headline)
            }

            // Rule #1: the wording gets more cautious as the tier gets weaker, never less.
            if result.isOfficial {
                Label("Official polling data", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Label(unofficialNotice, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("polling.unofficialNotice")
            }

            Link(
                "Find your assigned polling place", destination: URL(string: "https://www.usa.gov/find-polling-place")!
            )
            .font(.subheadline.bold())
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            result.isOfficial ? Color.green.opacity(0.09) : Color.orange.opacity(0.10),
            in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
    }

    private var unofficialNotice: String {
        if result.isWidened {
            return "We can’t confirm your polling place. We widened the search beyond your immediate area. "
                + "We have no evidence that these buildings offer voting; none is a confirmed polling place."
        }
        return "We can’t confirm your polling place. We have no evidence that these nearby buildings offer voting. "
            + "Use an official lookup to find your assigned polling place."
    }

    private func isSaved(_ location: PollingLocation) -> Bool {
        savedPlace?.name == location.name && savedPlace?.addr == location.addr
    }
}
