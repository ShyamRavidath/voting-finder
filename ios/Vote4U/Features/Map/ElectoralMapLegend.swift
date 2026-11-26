import SwiftUI

struct ElectoralMapLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("2024 & 2028 electoral votes")
                .font(.subheadline.bold())
            Text(
                "Each state’s allocation is based on the 2020 Census. These are electoral vote counts, not election results or a forecast."
            )
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
        .foregroundStyle(Vote4UTheme.supportingText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
