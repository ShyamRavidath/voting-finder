import SwiftUI

struct HomeView: View {
    private let election = ElectionCalendar.next()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    countdown
                    Text("Vote4U is independent and nonpartisan. It is not affiliated with any government agency, election office, campaign or party.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Vote4U")
        }
    }

    private var countdown: some View {
        VStack(spacing: 8) {
            Text(election.kind)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("\(election.daysAway)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(election.daysAway == 1 ? "day away" : "days away")
                .font(.title3)
            Text(election.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(election.kind) in \(election.daysAway) days")
    }
}

#Preview { HomeView() }
