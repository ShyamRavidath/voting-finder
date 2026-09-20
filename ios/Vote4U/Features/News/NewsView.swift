import SwiftUI

/// Phase 2: headline list from /api/news, opened in SFSafariViewController.
struct NewsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Election news",
                systemImage: "newspaper",
                description: Text("Coming in the next build.")
            )
            .navigationTitle("News")
        }
    }
}

#Preview { NewsView() }
