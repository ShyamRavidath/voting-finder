import SwiftUI

struct ElectoralStateShapeView: View {
    let shape: StateShape
    let state: ElectoralState?
    let scale: Double
    let isSelected: Bool
    let onSelect: (ElectoralState) -> Void

    var body: some View {
        let path = SVGPath.parse(shape.d, scale: CGSize(width: scale, height: scale))

        Button(action: select) {
            path
                .fill(state?.party.color ?? .gray)
                .overlay {
                    path.stroke(
                        isSelected ? Color.primary : Color.white.opacity(0.85),
                        lineWidth: isSelected ? 2 : 0.5
                    )
                }
        }
        .buttonStyle(.plain)
        .disabled(state == nil)
        .accessibilityHidden(true)
    }

    private func select() {
        if let state {
            onSelect(state)
        }
    }
}
