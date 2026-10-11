import SwiftUI

struct ElectionCountdownCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize = 60.0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 3_600)) { context in
            let election = ElectionCalendar.next(from: context.date)

            ZStack(alignment: .topTrailing) {
                Image(systemName: "calendar")
                    .font(.system(size: 96))
                    .foregroundStyle(.tint.opacity(0.08))
                    .offset(x: 6, y: 4)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 12) {
                    Label(election.kind, systemImage: "calendar.badge.clock")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(election.daysAway)")
                            .font(.system(size: countdownSize, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.55)
                            .lineLimit(1)
                            .contentTransition(.numericText(value: Double(election.daysAway)))
                            .animation(reduceMotion ? nil : .snappy, value: election.daysAway)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)

                        Text(election.daysAway == 1 ? "day" : "days")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }

                    Text(election.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(Vote4UTheme.heroBackground, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Vote4UTheme.cardCornerRadius)
                    .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "\(election.kind) in \(election.daysAway) days, \(election.date.formatted(date: .complete, time: .omitted))"
            )
        }
    }
}

#Preview {
    ElectionCountdownCard()
        .padding()
}
