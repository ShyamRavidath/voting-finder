import SwiftUI

struct HomeView: View {
    @Binding var selection: Tab

    @State private var reminders = ReminderPreferences.shared
    @State private var savedPlace: SavedPlace?

    private var reminderBinding: Binding<Bool> {
        // This explicit binding is deliberate: reverting a denied toggle through onChange would
        // re-enter the handler and erase the denial explanation.
        Binding(
            get: { reminders.enabled },
            set: { wantsReminders in
                reminders.setEnabled(wantsReminders)
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
                        permissionDenied: reminders.permissionDenied
                    )

                    NonpartisanNotice()
                    AppInformationLinks()
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

        await reminders.reconcile().value
    }
}

#Preview { HomeView(selection: .constant(.home)) }
