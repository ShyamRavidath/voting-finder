import SwiftUI

struct ElectoralMapCanvas: View {
    let paths: StatePaths
    let statesByName: [String: ElectoralState]
    let selected: ElectoralState?
    let onSelect: (ElectoralState) -> Void

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / paths.viewBox.width

            ZStack {
                ForEach(paths.shapes) { shape in
                    let state = statesByName[shape.name]
                    ElectoralStateShapeView(
                        shape: shape,
                        state: state,
                        scale: scale,
                        isSelected: selected == state,
                        onSelect: onSelect
                    )
                }
            }
        }
        .aspectRatio(paths.viewBox.width / paths.viewBox.height, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Map of the United States colored by electoral rating. Use the searchable state list below to select a state."
        )
    }
}
