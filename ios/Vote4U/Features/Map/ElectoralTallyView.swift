import SwiftUI

struct ElectoralTallyView: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ElectoralState.Party.allCases, id: \.self) { party in
                VStack(spacing: 3) {
                    Text(party.label)
                        .font(.caption)
                        .foregroundStyle(party.color)
                        .multilineTextAlignment(.center)
                    Text("\(BundledData.tally(for: party))")
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(party.label): \(BundledData.tally(for: party)) electoral votes")
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
    }
}
