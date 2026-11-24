import SwiftUI

struct LocalCivicView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var store = CivicStore()
    @State private var live = CivicFeedStore()
    @State private var section = LocalSection.help
    @State private var query = ""
    @FocusState private var queryFocused: Bool
    @State private var showPast = false
    @State private var resultLimit = 30

    private enum LocalSection: String, CaseIterable {
        case help = "Get help"
        case meetings = "Meetings"
        case following = "Following"
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.communitySelected {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        List {
                            Section {
                                VStack(alignment: .leading, spacing: 12) {
                                    sectionPicker
                                    Text(live.refreshing ? "Checking city pages…" : live.message)
                                        .font(.footnote).foregroundStyle(Vote4UTheme.supportingText)
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                            }
                            switch section {
                            case .help: help
                            case .meetings: meetings(now: context.date)
                            case .following: following
                            }
                            Section {
                                Link(
                                    "Portland.gov",
                                    destination: URL(string: "https://www.portland.gov")!)
                            } footer: {
                                Text(
                                    "From official city sources. Confirm details on the linked page before attending. Vote4U is independent of government. In-app search and following stay on this device."
                                )
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .refreshable { await refresh() }
                    }
                } else {
                    welcome
                }
            }
            .navigationTitle(store.communitySelected ? "Portland" : "Local decisions")
            .navigationDestination(for: String.self) { id in CivicMeetingView(meetingID: id, store: live) }
            .toolbar {
                if store.communitySelected {
                    Button("Refresh", systemImage: "arrow.clockwise") { Task { await refresh() } }
                        .disabled(live.refreshing)
                    Button("Change city", systemImage: "building.2") { store.changeCommunity() }
                }
            }
            .task(id: store.communitySelected) { if store.communitySelected { await refresh() } }
            .onChange(of: scenePhase) {
                if scenePhase == .active && store.communitySelected { Task { await refresh() } }
            }
            .onChange(of: query) { resultLimit = 30 }
            #if DEBUG
                .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("-civicDarkAppearance") ? .dark : nil)
            #endif
        }
    }

    private var welcome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(.largeTitle)).foregroundStyle(.tint).accessibilityHidden(true)
                Text("See decisions being made.")
                    .font(.largeTitle.bold()).fixedSize(horizontal: false, vertical: true)
                Text("Find the right city service. See upcoming meetings and what Council decided.")
                    .font(.title3).foregroundStyle(Vote4UTheme.supportingText)
                Button {
                    store.selectCommunity()
                } label: {
                    HStack {
                        Text("Explore Portland, Oregon").font(.headline)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }.padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent).tint(Vote4UTheme.actionBlue).controlSize(.large)
                .accessibilityIdentifier("civic.choosePortland")
                Text("Portland is the first city available. Choosing it doesn’t confirm where you live.")
                    .font(.footnote).foregroundStyle(Vote4UTheme.supportingText)
                Link("Find another city’s website", destination: URL(string: "https://www.usa.gov/local-governments")!)
            }
            .padding(24).frame(maxWidth: 600, alignment: .leading)
        }
        .background(Vote4UTheme.pageBackground)
    }

    private var sectionPicker: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(LocalSection.allCases, id: \.self) { item in
                        Button {
                            section = item
                        } label: {
                            HStack {
                                Text(item.rawValue)
                                Spacer()
                                if section == item { Image(systemName: "checkmark") }
                            }
                            .frame(minHeight: 44)
                        }.accessibilityIdentifier("civic.section.\(item.rawValue)")
                    }
                }
            } else {
                Picker("Local section", selection: $section) {
                    ForEach(LocalSection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
            }
        }
    }

    private var help: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What do you need help with?").font(.title2.bold())
                    Text("Search Portland’s services and resources.").foregroundStyle(Vote4UTheme.supportingText)
                    HStack {
                        if !typeSize.isAccessibilitySize {
                            Image(systemName: "magnifyingglass").foregroundStyle(Vote4UTheme.supportingText)
                        }
                        TextField("Try drugs, potholes, housing…", text: $query)
                            .autocorrectionDisabled().submitLabel(.search)
                            .focused($queryFocused).onSubmit { queryFocused = false }
                            .accessibilityIdentifier("civic.search")
                        if !query.isEmpty {
                            Button("Clear search", systemImage: "xmark.circle.fill") { query = "" }
                                .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .padding(.horizontal, 12).frame(minHeight: 48)
                    .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))
                }.padding(.vertical, 8)
            }
            let services = live.feed?.services.items ?? []
            let searching = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let matches = rankedServices(services)
            let common = [
                "/police/drug-complaint",
                "/transportation/maintenance/report-pothole-sinkhole-or-emergency-road-hazard", "/parks/report",
                "/311/contact-311",
                "/transportation/823-safe",
            ]
            Section {
                if searching {
                    if matches.isEmpty {
                        Text("No matching service. Try a shorter phrase, or ask 311 below.")
                            .accessibilityIdentifier("civic.noResults")
                    }
                    ForEach(matches.prefix(resultLimit)) { service in serviceLink(service) }
                    if matches.count > resultLimit { Button("Show more results") { resultLimit += 30 } }
                } else {
                    ForEach(services.filter { common.contains($0.id) }) { service in serviceLink(service) }
                    NavigationLink("Browse all \(services.count) services") {
                        CivicServiceDirectory(services: services)
                    }
                }
            } header: {
                Text(searching ? (matches.count == 1 ? "1 result" : "\(matches.count) results") : "Common requests")
            } footer: {
                if let date = live.feed?.services.fetchedAt {
                    Text("Directory downloaded \(date.formatted(date: .abbreviated, time: .shortened)).")
                }
            }
            Section {
                Link(destination: URL(string: "https://www.portland.gov/311")!) {
                    Label("Ask 311 where to start", systemImage: "questionmark.circle")
                }
                Link("Search on Portland.gov", destination: officialSearchURL)
            }
            if let catalog = store.catalog {
                Section("How city decisions work") {
                    ForEach(catalog.topics) { topic in
                        NavigationLink(topic.title) { CivicTopicView(topicID: topic.id, store: store, feedStore: live) }
                            .accessibilityIdentifier("civic.topic.\(topic.id)")
                    }
                }
            }
        }
    }

    private func rankedServices(_ services: [CivicService]) -> [CivicService] {
        let scored = services.map { (service: $0, score: $0.searchScore(query)) }
        return scored.filter { $0.score > 0 }.sorted { lhs, rhs in
            if lhs.score == rhs.score { return lhs.service.title < rhs.service.title }
            return lhs.score > rhs.score
        }.map { $0.service }
    }

    private var officialSearchURL: URL {
        var parts = URLComponents(string: "https://www.portland.gov/services")!
        parts.queryItems = [URLQueryItem(name: "search", value: query)]
        return parts.url!
    }

    private func serviceLink(_ service: CivicService) -> some View {
        Link(destination: service.url) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(service.displayTitle).font(.headline).foregroundStyle(Color.primary)
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
                if !service.displaySummary.isEmpty {
                    Text(service.displaySummary).font(.subheadline).foregroundStyle(Vote4UTheme.supportingText)
                        .lineLimit(3)
                }
                Text("Open city service").font(.caption).foregroundStyle(.tint)
            }.padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("civic.service.\(service.id)")
    }

    private func meetings(now: Date) -> some View {
        Group {
            Section {
                Text(showPast ? "Past meetings and records" : "Take part in a meeting").font(.title2.bold())
                Picker("Meeting dates", selection: $showPast) {
                    Text("Upcoming").tag(false)
                    Text("Past meetings").tag(true)
                }.pickerStyle(.segmented)
                NavigationLink("Recent council actions") { CivicActionsView(store: live) }
            }
            Section {
                let items = (live.feed?.meetings.items ?? []).filter {
                    showPast ? $0.startsAt <= now : $0.startsAt > now
                }
                .sorted { showPast ? $0.startsAt > $1.startsAt : $0.startsAt < $1.startsAt }
                if items.isEmpty {
                    Text(
                        showPast
                            ? "No past meetings in this copy."
                            : "No upcoming meetings in this copy. Open the city calendar for the full schedule.")
                }
                ForEach(items) { meeting in meetingRow(meeting) }
            } footer: {
                if let date = live.feed?.meetings.fetchedAt {
                    Text(
                        "Recent public meetings from the city calendar. Checked \(date.formatted(date: .abbreviated, time: .shortened))."
                    )
                }
            }
            Section {
                Link("Full city meeting calendar", destination: URL(string: "https://www.portland.gov/council/events")!)
                Link(
                    "How to speak or send comments",
                    destination: URL(string: "https://www.portland.gov/auditor/council-clerk/engage-council")!)
            }
        }
    }

    private var following: some View {
        Group {
            Section {
                Text("Your meetings").font(.title2.bold())
                Text(
                    "Tap Follow on a meeting to keep it here. Details update when you open Local; following doesn’t send notifications."
                )
                .font(.subheadline).foregroundStyle(Vote4UTheme.supportingText)
            }
            Section {
                if live.followedMeetings.isEmpty {
                    ContentUnavailableView(
                        "No meetings followed yet", systemImage: "bookmark",
                        description: Text("Find a meeting you care about, then tap Follow."))
                    Button("Browse meetings") { section = .meetings }
                }
                ForEach(live.followedMeetings.values.sorted { $0.startsAt < $1.startsAt }) { meeting in
                    meetingRow(meeting)
                }
            }
            if let catalog = store.catalog, !store.followed.isEmpty {
                Section("Saved guides") {
                    ForEach(catalog.topics.filter { store.followed.contains($0.id) }) { topic in
                        NavigationLink(topic.title) { CivicTopicView(topicID: topic.id, store: store, feedStore: live) }
                    }
                }
            }
        }
    }

    private func meetingRow(_ meeting: CivicMeeting) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(value: meeting.id) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(meeting.dateLabel).font(.subheadline.weight(.semibold)).foregroundStyle(.tint)
                    Text(meeting.shortTitle).font(.headline)
                    if meeting.status != "scheduled" { Text(meeting.status.capitalized).font(.subheadline.bold()) }
                }
            }.accessibilityIdentifier("civic.meeting.\(meeting.id)")
            Button {
                live.toggleFollow(meeting)
            } label: {
                Label(
                    live.followedMeetings[meeting.id] == nil ? "Follow" : "Following",
                    systemImage: live.followedMeetings[meeting.id] == nil ? "bookmark" : "bookmark.fill"
                )
                .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                live.followedMeetings[meeting.id] == nil
                    ? "Follow \(meeting.shortTitle)" : "Unfollow \(meeting.shortTitle)")
        }.padding(.vertical, 6)
    }

    private func refresh() async {
        async let guides: Void = store.refresh()
        async let feed: Void = live.refresh()
        _ = await (guides, feed)
    }
}

private struct CivicServiceDirectory: View {
    let services: [CivicService]
    @State private var query = ""

    var body: some View {
        List(services.filter { $0.searchScore(query) > 0 }.sorted { $0.title < $1.title }) { service in
            Link(destination: service.url) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(service.displayTitle).font(.headline).foregroundStyle(Color.primary)
                    Text(service.displaySummary).font(.subheadline).foregroundStyle(Vote4UTheme.supportingText)
                        .lineLimit(3)
                }.padding(.vertical, 6)
            }
        }
        .navigationTitle("City services")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search services")
    }
}
