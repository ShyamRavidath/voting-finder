import SwiftUI

struct CivicMeetingView: View {
    let meetingID: String
    let store: CivicFeedStore
    @State private var lastKnown: CivicMeeting?
    @State private var calendarMeeting: CivicMeeting?
    @State private var calendarMessage: String?

    init(meetingID: String, store: CivicFeedStore) {
        self.meetingID = meetingID
        self.store = store
        _lastKnown = State(initialValue: store.meeting(meetingID))
    }

    var body: some View {
        Group {
            if let meeting = store.meeting(meetingID) ?? lastKnown {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    let fetchedAt = store.feed?.meetings.fetchedAt ?? .distantPast
                    let listed = store.feed?.meetings.items.contains { $0.id == meeting.id } == true
                    let canSave = meeting.canSave(at: context.date, fetchedAt: fetchedAt, listed: listed)
                    List {
                        Section {
                            Text(meeting.shortTitle).font(.title.bold())
                            Text(meeting.dateLabel).font(.title3.weight(.semibold)).foregroundStyle(.tint)
                            if meeting.status != "scheduled" { Text(meeting.status.capitalized).font(.headline) }
                            Button {
                                store.toggleFollow(meeting)
                            } label: {
                                Label(
                                    store.followedMeetings[meeting.id] == nil ? "Follow meeting" : "Unfollow meeting",
                                    systemImage: store.followedMeetings[meeting.id] == nil
                                        ? "bookmark" : "bookmark.fill")
                            }.accessibilityIdentifier("civic.followMeeting")
                        }
                        Section {
                            Link(destination: meeting.url) {
                                Label("Open meeting page", systemImage: "arrow.up.right.square")
                            }.accessibilityIdentifier("civic.meetingLink")
                            if meeting.startsAt > context.date && meeting.status == "scheduled" {
                                Link(
                                    "How to speak or send comments",
                                    destination: URL(
                                        string: "https://www.portland.gov/auditor/council-clerk/engage-council")!)
                                Button("Add to Calendar", systemImage: "calendar.badge.plus") {
                                    guard meeting.canSave(at: .now, fetchedAt: fetchedAt, listed: listed) else {
                                        return
                                    }
                                    calendarMeeting = meeting
                                }
                                .disabled(!canSave).accessibilityIdentifier("civic.calendar")
                                if !canSave {
                                    Text("Refresh this meeting before adding it to Calendar.").font(.footnote)
                                    Button("Check for updates") { Task { await store.refresh() } }.disabled(
                                        store.refreshing)
                                }
                            }
                            if let calendarMessage { Text(calendarMessage).font(.footnote) }
                        } footer: {
                            if meeting.startsAt > context.date {
                                Text(
                                    "Calendar events are copies; later changes won’t update them. Confirm the meeting page before attending."
                                )
                            }
                        }
                        if meeting.startsAt <= context.date {
                            Section("Records") {
                                let actions =
                                    store.feed?.actions.items.filter {
                                        abs($0.meetingAt.timeIntervalSince(meeting.startsAt)) < 60
                                    } ?? []
                                if actions.isEmpty {
                                    Text("No council actions from this meeting are in the current feed.")
                                }
                                ForEach(actions) { action in
                                    NavigationLink(action.displayTitle) { CivicActionView(action: action) }
                                }
                                Link(
                                    "Find minutes and recordings",
                                    destination: URL(string: "https://www.portland.gov/auditor/council-clerk/records")!)
                            }
                        }
                        if !meeting.summary.isEmpty {
                            Section {
                                DisclosureGroup("About this meeting") {
                                    Text(meeting.summary).foregroundStyle(Vote4UTheme.supportingText)
                                }
                            }
                        }
                        Section {
                            if !listed {
                                Text(
                                    "This meeting is outside the city’s recent listings. Your saved link is still available."
                                )
                            }
                            Text("City calendar checked \(fetchedAt.formatted(date: .abbreviated, time: .shortened)).")
                                .font(.footnote).foregroundStyle(Vote4UTheme.supportingText)
                        }
                    }
                    .onChange(of: canSave) { if !canSave { calendarMeeting = nil } }
                }
                .onChange(of: meeting) {
                    if calendarMeeting != nil {
                        calendarMeeting = nil
                        calendarMessage = "The meeting changed. Review its new details before saving."
                    }
                }
            } else {
                ContentUnavailableView(
                    "Meeting unavailable", systemImage: "calendar",
                    description: Text("Open the city calendar from Meetings."))
            }
        }
        .navigationTitle("Meeting").navigationBarTitleDisplayMode(.inline)
        .onChange(of: store.meeting(meetingID)) {
            if let updated = store.meeting(meetingID) { lastKnown = updated }
        }
        .sheet(item: $calendarMeeting) { meeting in
            CivicCalendarEditor(meeting: meeting) { saved in
                calendarMessage = saved ? "Saved to Calendar." : "Calendar save cancelled."
                calendarMeeting = nil
            }
        }
    }
}

struct CivicActionsView: View {
    let store: CivicFeedStore
    var body: some View {
        List {
            Section {
                Text("What Council did").font(.title2.bold())
                Text(
                    "Actions recorded on recent Council agendas. A next reading or referral is a step in the process, not final approval."
                )
                .foregroundStyle(Vote4UTheme.supportingText)
            }
            Section {
                ForEach(store.feed?.actions.items ?? []) { action in
                    NavigationLink {
                        CivicActionView(action: action)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(action.displayTitle).font(.headline)
                            Text(action.action).font(.subheadline).foregroundStyle(.tint)
                            Text(action.id).font(.caption).foregroundStyle(Vote4UTheme.supportingText)
                        }.padding(.vertical, 6)
                    }
                }
            } footer: {
                if let date = store.feed?.actions.fetchedAt {
                    Text("Agenda checked \(date.formatted(date: .abbreviated, time: .shortened)).")
                }
            }
            Link(
                "All council records",
                destination: URL(string: "https://www.portland.gov/auditor/council-clerk/records")!)
        }.navigationTitle("Council actions").navigationBarTitleDisplayMode(.inline)
    }
}

struct CivicActionView: View {
    let action: CivicAction
    var body: some View {
        List {
            Section {
                Text(action.displayTitle).font(.title2.bold())
                Text("Item \(action.id)").font(.subheadline).foregroundStyle(Vote4UTheme.supportingText)
            }
            Section("Recorded action") {
                Text(action.action).font(.headline)
                if !action.notes.isEmpty { Text(action.notes) }
            }
            Section {
                Link("Read the proposal and documents", destination: action.url)
                Link("Open this meeting’s agenda", destination: action.agendaURL)
                if let videoURL = action.videoURL { Link("Watch the meeting recording", destination: videoURL) }
            }
            Section("Official title") { Text(action.title).foregroundStyle(Vote4UTheme.supportingText) }
        }.navigationTitle("Council action").navigationBarTitleDisplayMode(.inline)
    }
}
