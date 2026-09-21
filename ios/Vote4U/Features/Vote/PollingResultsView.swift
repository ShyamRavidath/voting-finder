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
                PollingMapView(locations: result.locations)

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
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("polling.unofficialNotice")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
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
