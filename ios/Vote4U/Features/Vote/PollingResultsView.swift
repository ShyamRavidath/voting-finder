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
                        "We checked official data, then nearby public buildings, then widened the search. "
                            + "Nothing came back, and we'd rather show you nothing than guess. "
                            + "Use an official lookup below."
                    )
                )
            } else {
                resultSummary
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

            OfficialSourcesView()
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

            Link("Confirm with an official lookup", destination: URL(string: "https://www.usa.gov/find-polling-place")!)
                .font(.subheadline.bold())
                .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            result.isOfficial ? Color.green.opacity(0.09) : Color.orange.opacity(0.10),
            in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
    }

    private var unofficialNotice: String {
        guard result.isWidened else {
            return "Likely locations from OpenStreetMap—not confirmed polling places. "
                + "Check an official source before you go."
        }
        let radius = result.searchRadiusMiles.map { " to about \($0) miles" } ?? ""
        return "Nothing polling-related was listed in your immediate area, so we widened the search\(radius). "
            + "These are civic buildings of the kind precincts often use—none is a confirmed polling place. "
            + "Check an official source below before you go."
    }

    private func isSaved(_ location: PollingLocation) -> Bool {
        savedPlace?.name == location.name && savedPlace?.addr == location.addr
    }
}
