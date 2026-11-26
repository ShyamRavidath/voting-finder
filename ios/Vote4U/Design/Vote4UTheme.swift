import SwiftUI

enum Vote4UTheme {
    // Keep supporting copy readable on both material appearances.
    static let supportingText = Color.primary.opacity(0.72)
    static let actionBlue = Color(red: 0.149, green: 0.388, blue: 0.851)

    static let cardCornerRadius = 16.0
    static let compactCornerRadius = 14.0
    static let sectionSpacing = 24.0

    static var pageBackground: Color { Color(.systemGroupedBackground) }
    static var heroBackground: Color { Color.accentColor.opacity(0.10) }
}
