import SwiftUI

struct VoteSearchErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ContentUnavailableView {
                Label("Couldn't search", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again", systemImage: "arrow.clockwise", action: onRetry)
                    .vote4UPrimaryActionStyle()
            }

            OfficialSourcesView()
        }
    }
}
