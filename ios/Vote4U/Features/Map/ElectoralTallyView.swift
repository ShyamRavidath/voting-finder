import SwiftUI

struct ElectoralTallyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("270 votes to win").font(.title.bold())
            Text(
                "\(BundledData.totalElectoralVotes) electoral votes across 50 states and D.C. Tap a state to see its share."
            )
            .font(.subheadline).foregroundStyle(Vote4UTheme.supportingText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
