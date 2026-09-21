import SwiftUI

struct PollingSearchLoadingView: View {
    private let placeholders = ["first", "second"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Finding polling places…", systemImage: "location.magnifyingglass")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(placeholders, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    Text("Polling place name")
                        .font(.title3.bold())
                    Text("Street address and city")
                        .font(.subheadline)
                    Text("Polling place")
                        .font(.caption)
                    RoundedRectangle(cornerRadius: Vote4UTheme.compactCornerRadius)
                        .frame(height: 48)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
                .redacted(reason: .placeholder)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Finding polling places")
        .allowsHitTesting(false)
    }
}
