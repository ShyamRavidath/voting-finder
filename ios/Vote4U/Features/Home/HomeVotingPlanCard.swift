import SwiftUI

struct HomeVotingPlanCard: View {
    let onFindPollingPlace: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Make your voting plan", systemImage: "list.clipboard.fill")
                .font(.title3.bold())

            Text("Find a polling place, save it for offline access, and get directions when it matters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onFindPollingPlace) {
                Label("Find a polling place", systemImage: "mappin.and.ellipse")
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
