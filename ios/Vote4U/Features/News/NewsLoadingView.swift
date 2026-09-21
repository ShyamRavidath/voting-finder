import SwiftUI

struct NewsLoadingView: View {
    private let placeholders = ["one", "two", "three", "four", "five"]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(placeholders, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Election news headline that spans two lines")
                            .font(.headline)
                        Text("Publisher · Just now")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
                    .redacted(reason: .placeholder)
                }
            }
            .padding()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading election news")
        .allowsHitTesting(false)
    }
}
