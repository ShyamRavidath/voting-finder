import SwiftUI

extension View {
    /// Liquid Glass is reserved for the primary interactive action on iOS 26+. Earlier systems
    /// keep the same hierarchy with the native prominent bordered style.
    @ViewBuilder
    func vote4UPrimaryActionStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glassProminent)
                .tint(Vote4UTheme.actionBlue)
        } else {
            buttonStyle(.borderedProminent)
                .tint(Vote4UTheme.actionBlue)
        }
    }
}
