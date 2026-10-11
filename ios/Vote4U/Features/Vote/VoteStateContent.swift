import SwiftUI

struct VoteStateContent: View {
    let state: VoteViewModel.State
    let savedPlace: SavedPlace?
    let onRetry: () -> Void
    let onSave: (PollingLocation) -> Void

    @ViewBuilder
    var body: some View {
        switch state {
        case .idle:
            OfficialSourcesView()
        case .loading:
            PollingSearchLoadingView()
        case .loaded(let result):
            PollingResultsView(result: result, savedPlace: savedPlace, onSave: onSave)
        case .locationUnavailable:
            VStack(alignment: .leading, spacing: 10) {
                Label("Search with your ZIP", systemImage: "keyboard")
                    .font(.headline)
                Text("Location access is optional. Enter a 5-digit ZIP code above, then tap Search.")
                    .font(.subheadline)
                    .foregroundStyle(Vote4UTheme.supportingText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.accentColor.opacity(0.08), in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
            OfficialSourcesView()
        case .failed(let message):
            VoteSearchErrorView(message: message, onRetry: onRetry)
        }
    }
}
