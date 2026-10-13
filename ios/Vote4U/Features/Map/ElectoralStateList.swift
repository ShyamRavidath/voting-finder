import SwiftUI

struct ElectoralStateList: View {
    let searchText: String
    let selected: ElectoralState?
    let onSelect: (ElectoralState) -> Void

    private var matchingStates: [ElectoralState] {
        let states = BundledData.statesAlphabetically
        guard !searchText.isEmpty else { return states }
        return states.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            Label("Electoral votes by state", systemImage: "list.bullet")
                .font(.title3.bold())

            if matchingStates.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                stateRows
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stateRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(matchingStates) { state in
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
                .accessibilityLabel("\(state.name), \(state.ev) electoral votes")
                .accessibilityAddTraits(selected == state ? .isSelected : [])

                if state.id != matchingStates.last?.id {
                    Divider()
                        .padding(.leading)
                }
            }
        }
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
    }
}
