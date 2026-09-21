import SwiftUI

struct ElectoralMapView: View {
    @State private var selected: ElectoralState?
    @State private var searchText = ""

    private let paths = BundledData.statePaths
    private let byName = Dictionary(
        uniqueKeysWithValues: BundledData.states.map { ($0.name, $0) }
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Vote4UTheme.sectionSpacing) {
                    ElectoralTallyView()
                    ElectoralMapCanvas(
                        paths: paths,
                        statesByName: byName,
                        selected: selected,
                        onSelect: select
                    )

                    if let selected {
                        ElectoralStateDetail(state: selected)
                    }

                    ElectoralMapLegend()
                    ElectoralStateList(
                        searchText: searchText,
                        selected: selected,
                        onSelect: select
                    )
                }
                .padding()
            }
            .background {
                Vote4UTheme.pageBackground
                    .ignoresSafeArea()
            }
            .navigationTitle("Electoral Map")
            // Pinned open rather than left to .automatic, which collapses the field behind the
            // title until the user scrolls up. A search control nobody can see is a search
            // control nobody uses — and it made the UI test unable to reach it at all.
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search states"
            )
        }
    }

    private func select(_ state: ElectoralState) {
        selected = selected == state ? nil : state
    }
}

#Preview { ElectoralMapView() }
