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
                    description: Text("We'd rather show you nothing than guess. Use an official lookup below.")
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

            if result.isOfficial {
                Label("Official polling data", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Label(
                    "Likely locations from OpenStreetMap—not confirmed polling places. Check an official source before you go.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
    }

    private func isSaved(_ location: PollingLocation) -> Bool {
        savedPlace?.name == location.name && savedPlace?.addr == location.addr
    }
}
