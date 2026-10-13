import SwiftUI

struct ElectoralTallyView: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 3) {
                Text("Total electoral votes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(BundledData.totalElectoralVotes)")
                    .font(.title2.bold())
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            VStack(spacing: 3) {
                Text("Majority needed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("270")
                    .font(.title2.bold())
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
        .multilineTextAlignment(.center)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
    }
}
