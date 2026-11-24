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

                    Button {
                        selection = .local
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "building.2").font(.title2).foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("What’s happening in Portland?").font(.headline).foregroundStyle(.primary)
                                Text("City services and public meetings").font(.subheadline).foregroundStyle(
                                    Vote4UTheme.supportingText)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(
                                Vote4UTheme.supportingText)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.local")

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
