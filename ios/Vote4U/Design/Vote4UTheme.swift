import SwiftUI

enum Vote4UTheme {
    // Keep supporting copy readable on both material appearances.
    static let supportingText = Color.primary.opacity(0.72)
    static let actionBlue = Color(red: 0.149, green: 0.388, blue: 0.851)

    static let cardCornerRadius = 20.0
    static let compactCornerRadius = 14.0
    static let sectionSpacing = 18.0

    static var pageBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.12),
                Color.accentColor.opacity(0.03),
                .clear,
            ],
            startPoint: .topLeading,
            endPoint: .center
        )
    }

    static var heroBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.2),
                Color.accentColor.opacity(0.07),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
