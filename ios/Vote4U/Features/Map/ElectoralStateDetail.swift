import SwiftUI

struct ElectoralStateDetail: View {
    let state: ElectoralState

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(state.name)
                    .font(.headline)
                Text("2024 & 2028 allocation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(state.ev)")
                    .font(.title2.bold())
                    .monospacedDigit()
                Text("electoral votes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.name), \(state.ev) electoral votes, selected")
        .accessibilityAddTraits(.isSelected)
    }
}
