import SwiftUI

struct HomeVotingPlanCard: View {
    let onFindPollingPlace: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Where will you vote?", systemImage: "list.clipboard.fill")
                .font(.title3.bold())

            Text(
                "Search your ZIP code, then confirm your assigned location with the election office. You can save a result here for offline use."
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
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
    }
}
