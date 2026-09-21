import SwiftUI

struct ElectoralMapLegend: View {
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text("270 electoral votes are needed to win.")
                    .font(.subheadline.bold())
                Text("Ratings are an editorial summary, not a prediction or an official result.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
