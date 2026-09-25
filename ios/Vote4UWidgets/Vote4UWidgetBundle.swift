import SwiftUI
import WidgetKit

/// The widget extension's entry point.
///
/// Everything here is computed offline from `ElectionCalendar`, which is compiled into this
/// target from the app's sources rather than duplicated — the election date drives the Home
/// countdown, the reminder schedule and now the widget, and three copies of that arithmetic
/// would be three chances to disagree.
///
/// Deliberately no network: a widget that can fail is a widget that shows a spinner on someone's
/// Home Screen. Polling places need a live lookup, so they stay in the app.
@main
struct Vote4UWidgetBundle: WidgetBundle {
    var body: some Widget {
        ElectionCountdownWidget()
    }
}
