import SwiftUI

struct ElectoralMapLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("2024 & 2028 electoral votes")
                .font(.subheadline.bold())
            Text("Allocations use the 2020 Census. This map shows vote counts, not a forecast or election result.")
            Text(
                "Maine and Nebraska each award two votes to the statewide winner and one per congressional district winner. State totals are shown here."
            )
            Link(
                "Source: National Archives",
                destination: URL(string: "https://www.archives.gov/electoral-college/allocation")!
            )
            Text("Verified October 11, 2026")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
