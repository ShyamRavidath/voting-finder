import SwiftUI
import WidgetKit

/// The countdown changes only at local midnight, so the timeline is one entry per midnight
/// rather than anything time-based. WidgetKit budgets refreshes per app per day; asking to be
/// woken hourly for a number that moves once a day is how a widget gets throttled and goes
/// stale — the exact failure it would be blamed for.
struct ElectionCountdownProvider: TimelineProvider {
    /// A week of entries, then `.atEnd` so WidgetKit comes back for more.
    private static let daysAhead = 7

    func placeholder(in context: Context) -> ElectionCountdownEntry {
        entry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ElectionCountdownEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ElectionCountdownEntry>) -> Void) {
        // The first date is "now", so the widget is correct the instant it is added rather than
        // at the next midnight. The sequence itself is tested in Vote4UTests.
        let entries = ElectionCalendar
            .countdownRefreshDates(from: Date(), count: Self.daysAhead)
            .map(entry(for:))

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Each entry is computed for *its own* date, not for "now". Reusing one count across the
    /// week would freeze the number at whatever it was when the timeline was built.
    private func entry(for date: Date) -> ElectionCountdownEntry {
        ElectionCountdownEntry(date: date, election: ElectionCalendar.next(from: date))
    }
}

struct ElectionCountdownWidget: Widget {
    private let kind = "ElectionCountdown"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ElectionCountdownProvider()) { entry in
            ElectionCountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Election Countdown")
        .description("Days until the next U.S. federal election.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
        ])
    }
}
