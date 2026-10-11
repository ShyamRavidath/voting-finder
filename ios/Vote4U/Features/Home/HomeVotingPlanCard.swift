import SwiftUI

struct HomeVotingPlanCard: View {
    let onFindPollingPlace: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Make your voting plan", systemImage: "list.clipboard.fill")
                .font(.title3.bold())

            Text(
                "Search by ZIP, confirm with an official source, then tap Save for offline on a result. Your saved location will appear here."
            )
            .font(.subheadline)
            .foregroundStyle(Vote4UTheme.supportingText)

            Button(action: onFindPollingPlace) {
                Label("Find a location", systemImage: "mappin.and.ellipse")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .vote4UPrimaryActionStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
    }
}
