import SwiftUI

struct HomeView: View {
    private let election = ElectionCalendar.next()

    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    countdown
                    reminderToggle
                    Text("Vote4U is independent and nonpartisan. It is not affiliated with any government agency, election office, campaign or party.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Vote4U")
            .task {
                // The system setting can be revoked outside the app, so trust it over our flag.
                if remindersEnabled, await !ReminderScheduler.isAuthorized() {
                    remindersEnabled = false
                }
            }
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

    private var reminderToggle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Remind me about Election Day", isOn: $remindersEnabled)
                .onChange(of: remindersEnabled) { _, enabled in
                    Task { await updateReminders(enabled: enabled) }
                }

            Text(permissionDenied
                 ? "Notifications are turned off for Vote4U. Turn them on in Settings to get reminders."
                 : "A reminder one week before, and again on Election Day morning. Everything is scheduled on your device.")
                .font(.caption)
                .foregroundStyle(permissionDenied ? .orange : .secondary)
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 12))
        .sensoryFeedback(.selection, trigger: remindersEnabled)
    }

    private func updateReminders(enabled: Bool) async {
        guard enabled else {
            ReminderScheduler.cancelAll()
            permissionDenied = false
            return
        }

        guard await ReminderScheduler.authorize() else {
            // Flip the switch back rather than leaving it on and silently scheduling nothing.
            remindersEnabled = false
            permissionDenied = true
            return
        }

        permissionDenied = false
        await ReminderScheduler.schedule()
    }
}

#Preview { HomeView() }
