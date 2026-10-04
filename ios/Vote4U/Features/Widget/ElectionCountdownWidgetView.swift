import SwiftUI
import WidgetKit

/// What the widget draws for a single point in time.
///
/// This file lives in the **app** target and is compiled into `Vote4UWidgets` by an explicit
/// reference, the same arrangement as `ElectionCalendar`. A test bundle cannot import an app
/// extension, so anything that lives only in the widget can never be rendered in a test — and a
/// widget that builds is not a widget that draws.
struct ElectionCountdownEntry: TimelineEntry {
    let date: Date
    let election: FederalElection
}

/// What the widget installs. Reads the family from the environment and hands it to
/// `ElectionCountdownContent`, which is the part that can be rendered in a test —
/// `\.widgetFamily` is a read-only environment key, so a test cannot set it.
struct ElectionCountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ElectionCountdownEntry

    var body: some View {
        ElectionCountdownContent(entry: entry, family: family)
    }
}

/// One layout per family. The Lock Screen accessory families are monochrome and tiny, so they
/// get their own treatment rather than a scaled-down Home Screen layout.
struct ElectionCountdownContent: View {
    let entry: ElectionCountdownEntry
    let family: WidgetFamily

    private var election: FederalElection { entry.election }

    var body: some View {
        content
            // Required on iOS 17: without it the system draws no background and logs a warning.
            .containerBackground(.fill.tertiary, for: .widget)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(election.spokenSummary())
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            // A single system-truncated line, so lead with the part that carries the meaning.
            Text("\(election.countdownPhrase) · \(election.shortKind())")
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .systemMedium:
            medium
        default:
            small
        }
    }

    // MARK: - Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(election.shortKind(), systemImage: "calendar.badge.clock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)

            countdown(numberSize: 46, wordSize: 30, unitFont: .headline)

            Spacer(minLength: 4)

            Text(election.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(election.kind)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Abbreviated: "Tuesday, November 3, 2026" wraps to two lines in this column.
                Text(election.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Check your polling place before you go.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // A *fixed* width, not maxWidth: a frame does not clip, so a Text that wants more
            // room simply draws past the edge — which is exactly what "Tomorrow" did here.
            // Given a definite width, `minimumScaleFactor` finally has something to scale to.
            countdown(numberSize: 52, wordSize: 26, unitFont: .subheadline)
                .frame(width: 124, alignment: .trailing)
                .layoutPriority(1)
        }
    }

    /// Number over unit rather than "43 days" on one line: three digits plus a word does not fit
    /// a small widget, and "Tomorrow" is wider still. Both were running edge to edge before.
    @ViewBuilder
    private func countdown(numberSize: CGFloat, wordSize: CGFloat, unitFont: Font) -> some View {
        if election.daysAway <= 1 {
            Text(election.countdownPhrase)
                .font(.system(size: wordSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        } else {
            VStack(alignment: .leading, spacing: -2) {
                Text("\(election.daysAway)")
                    .font(.system(size: numberSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("days")
                    .font(unitFont)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Lock Screen

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(election.shortKind())
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(election.countdownPhrase)
                .font(.title3.weight(.bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(election.date, format: .dateTime.month(.abbreviated).day())
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Roughly 76 pt across: numbers and units on ordinary days, "Today" on Election Day.
    /// "Tomorrow" cannot fit legibly at this size.
    private var circular: some View {
        let display = election.circularCountdown
        return VStack(spacing: -1) {
            Text(display.value)
                .font(display.unit == nil ? .caption.weight(.bold) : .title2.weight(.bold))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            if let unit = display.unit {
                Text(unit)
                    .font(.system(size: 10))
            }
        }
    }
}
