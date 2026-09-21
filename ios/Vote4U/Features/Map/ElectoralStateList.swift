import SwiftUI

struct ElectoralStateList: View {
    let searchText: String
    let selected: ElectoralState?
    let onSelect: (ElectoralState) -> Void

    private var hasResults: Bool {
        ElectoralState.Party.allCases.contains { !states(for: $0).isEmpty }
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            Label("State ratings", systemImage: "list.bullet")
                .font(.title3.bold())

            if hasResults {
                ForEach(ElectoralState.Party.allCases, id: \.self) { party in
                    let matchingStates = states(for: party)
                    if !matchingStates.isEmpty {
                        partySection(party, states: matchingStates)
                    }
                }
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func states(for party: ElectoralState.Party) -> [ElectoralState] {
        let states = BundledData.statesByParty[party] ?? []
        guard !searchText.isEmpty else { return states }
        return states.filter { $0.name.localizedStandardContains(searchText) }
    }

    private func partySection(
        _ party: ElectoralState.Party,
        states: [ElectoralState]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(party.label)
                .font(.subheadline.bold())
                .foregroundStyle(party.color)
                .padding(.horizontal)
                .padding(.vertical, 12)

            Divider()

            ForEach(states) { state in
                Button {
                    onSelect(state)
                } label: {
                    HStack {
                        Text(state.name)
                        Spacer()
                        Text("\(state.ev)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .accessibilityLabel("\(state.name), \(state.ev) electoral votes, \(party.label)")
                .accessibilityAddTraits(selected == state ? .isSelected : [])

                if state.id != states.last?.id {
                    Divider()
                        .padding(.leading)
                }
            }
        }
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
    }
}
