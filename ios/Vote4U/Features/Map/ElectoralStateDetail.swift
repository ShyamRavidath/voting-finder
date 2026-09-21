import SwiftUI

struct ElectoralStateDetail: View {
    let state: ElectoralState

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(state.party.color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(state.name)
                    .font(.headline)
                Text(state.party.label)
                    .font(.subheadline)
                    .foregroundStyle(state.party.color)
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
        .accessibilityLabel("\(state.name), \(state.ev) electoral votes, \(state.party.label), selected")
        .accessibilityAddTraits(.isSelected)
    }
}
