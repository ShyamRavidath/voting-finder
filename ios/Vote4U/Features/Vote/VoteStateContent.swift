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
        case .failed(let message):
            VoteSearchErrorView(message: message, onRetry: onRetry)
        }
    }
}
