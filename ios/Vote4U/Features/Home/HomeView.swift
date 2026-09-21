import SwiftUI

struct HomeView: View {
    @Binding var selection: Tab

    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @State private var permissionDenied = false
    @State private var savedPlace: SavedPlace?

    private var reminderBinding: Binding<Bool> {
        // This explicit binding is deliberate: reverting a denied toggle through onChange would
        // re-enter the handler and erase the denial explanation.
        Binding(
            get: { remindersEnabled },
            set: { wantsReminders in
                remindersEnabled = wantsReminders
                Task { await updateReminders(enabled: wantsReminders) }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Vote4UTheme.sectionSpacing) {
                    ElectionCountdownCard()

                    if let savedPlace {
                        HomeSavedPlaceCard(place: savedPlace, onOpenVote: openVoteTab)
                    } else {
                        HomeVotingPlanCard(onFindPollingPlace: openVoteTab)
                    }

                    ElectionReminderCard(
                        isEnabled: reminderBinding,
                        permissionDenied: permissionDenied
                    )

                    NonpartisanNotice()
                }
                .padding()
            }
            .background {
                Vote4UTheme.pageBackground
                    .ignoresSafeArea()
            }
            .navigationTitle("Vote4U")
            .task(id: selection) { await refreshIfVisible() }
        }
    }

    private func openVoteTab() {
        selection = .vote
    }

    private func refreshIfVisible() async {
        guard selection == .home else { return }
        savedPlace = SavedPlaceStore.load()

        // The system setting can be revoked outside the app, so trust it over our stored flag.
        if remindersEnabled, await !ReminderScheduler.isAuthorized() {
            remindersEnabled = false
        }
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

#Preview { HomeView(selection: .constant(.home)) }
