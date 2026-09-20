import SwiftUI

struct ElectoralMapView: View {
    @State private var selected: ElectoralState?

    private let paths = BundledData.statePaths
    private let states = BundledData.states

    private var byName: [String: ElectoralState] {
        Dictionary(uniqueKeysWithValues: states.map { ($0.name, $0) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    tally
                    map
                    if let selected { detail(for: selected) }
                    legend
                }
                .padding()
            }
            .navigationTitle("Electoral Map")
        }
    }

    private var tally: some View {
        HStack(spacing: 12) {
            ForEach(ElectoralState.Party.allCases, id: \.self) { party in
                VStack(spacing: 2) {
                    Text(party.label)
                        .font(.caption2)
                        .foregroundStyle(party.color)
                        .multilineTextAlignment(.center)
                    Text("\(BundledData.tally(for: party))")
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(BundledData.totalElectoralVotes) electoral votes total, 270 to win"))
    }

    private var map: some View {
        // The source canvas is 975x610; scaling to the available width keeps every state aligned.
        GeometryReader { geometry in
            let scale = geometry.size.width / paths.viewBox.width

            ZStack {
                ForEach(paths.shapes) { shape in
                    let state = byName[shape.name]
                    let path = SVGPath.parse(shape.d, scale: CGSize(width: scale, height: scale))

                    path
                        .fill(state?.party.color ?? .gray)
                        .overlay(path.stroke(.background, lineWidth: 0.5))
                        .onTapGesture {
                            guard let state else { return }
                            selected = selected == state ? nil : state
                        }
                        .accessibilityLabel(state.map { "\($0.name), \($0.ev) electoral votes, \($0.party.label)" } ?? shape.name)
                }
            }
        }
        .aspectRatio(paths.viewBox.width / paths.viewBox.height, contentMode: .fit)
    }

    private func detail(for state: ElectoralState) -> some View {
        VStack(spacing: 4) {
            Text(state.name).font(.headline)
            Text("\(state.ev) electoral votes").font(.subheadline)
            Text(state.party.label)
                .font(.caption)
                .foregroundStyle(state.party.color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 12))
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("270 electoral votes are needed to win.")
                .font(.footnote)
            Text("Ratings are an editorial summary, not a prediction or an official result.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview { ElectoralMapView() }
