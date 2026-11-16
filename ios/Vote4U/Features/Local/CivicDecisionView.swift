import SwiftUI

struct CivicDecisionView: View {
    let decisionID: String
    let store: CivicStore
    @State private var showingCalendar = false
    @State private var calendarMessage: String?

    var body: some View {
        Group {
            if let decision = store.catalog?.decisions.first(where: { $0.id == decisionID }) {
                detail(decision)
            } else {
                ContentUnavailableView(
                    "Item no longer listed", systemImage: "doc.text.magnifyingglass",
                    description: Text(
                        "This item was removed from the updated guide. Check the official Council agenda."))
            }
        }
        .navigationTitle("Before they vote")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detail(_ decision: CivicDecision) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            List {
                Section {
                    Text(decision.title).font(.title2.bold())
                    Text("Source check: \(decision.checkedAt.formatted(date: .abbreviated, time: .omitted))").font(
                        .footnote)
                    Text("\(decision.body) • \(decision.id)")
                    Text(decision.statusLabel(at: context.date)).font(.headline)
                }
                Section("The proposal") { Text(decision.proposal) }
                Section("What would change?") { Text(decision.change) }
                Section("Meeting") {
                    Text(decision.formatted(decision.meetingAt))
                    Text(decision.meetingLabel)
                    Button("Save meeting to Calendar", systemImage: "calendar.badge.plus") {
                        guard decision.canSaveCalendar(at: Date()) else { return }
                        showingCalendar = true
                    }
                    .disabled(!decision.canSaveCalendar(at: context.date))
                    .accessibilityIdentifier("civic.calendar")
                    if !decision.canSaveCalendar(at: context.date) {
                        Text(
                            "Calendar saving is unavailable for past, changed, or out-of-date meetings. Check the official agenda."
                        ).font(.footnote)
                    }
                    Text("Calendar copies do not update automatically. Confirm the agenda before attending.").font(
                        .footnote)
                    if let calendarMessage { Text(calendarMessage).font(.footnote) }
                }
                Section("Participate") {
                    if let deadline = decision.commentDeadline {
                        Text("Virtual sign-up: \(decision.formatted(deadline))")
                        if context.date >= deadline { Text("This listed sign-up deadline has passed.").bold() }
                    } else {
                        Text("No verified sign-up deadline. Check the official agenda.")
                    }
                    if !decision.isCurrent(at: context.date) {
                        Text("Participation details need rechecking; do not rely on this saved deadline.").bold()
                    }
                    Text(decision.deadlineLabel)
                    Text(decision.participation)
                    Link(
                        "Check agenda and participation options",
                        destination: URL(string: "https://www.portland.gov/council/agenda")!)
                }
                Section("What happened?") {
                    if let outcome = decision.outcome {
                        Text(outcome.summary)
                        Text("Recorded \(outcome.recordedAt.formatted(date: .abbreviated, time: .omitted))")
                        Link(outcome.source.title, destination: outcome.source.url)
                    } else {
                        Text(
                            "No final outcome verified in this guide. A scheduled meeting or committee recommendation is not approval, funding, or completion."
                        )
                    }
                }
                CivicSourcesView(
                    checkedAt: decision.checkedAt, reviewBy: decision.reviewBy, sources: decision.sources,
                    now: context.date)
            }
        }
        .onChange(of: decision) {
            if showingCalendar {
                showingCalendar = false
                calendarMessage = "The source record changed. Review the updated details before saving."
            }
        }
        .sheet(isPresented: $showingCalendar) {
            CivicCalendarEditor(decision: decision) { saved in
                calendarMessage =
                    saved ? "Saved to Calendar. Recheck the official agenda for changes." : "Calendar save cancelled."
                showingCalendar = false
            }
        }
    }
}
