import SwiftUI

struct LocalCivicView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = CivicStore()
    @State private var query = ""
    @State private var followingOnly = false
    @State private var showPast = false

    var body: some View {
        NavigationStack {
            Group {
                if !store.communitySelected {
                    communityPicker
                } else {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        guide(now: context.date)
                    }
                }
            }
            .navigationTitle("Local decisions")
            .toolbar {
                if store.communitySelected {
                    Button("Change community") { store.changeCommunity() }
                }
            }
            .task(id: store.communitySelected) { await store.refresh() }
            .onChange(of: scenePhase) {
                if scenePhase == .active { Task { await store.refresh() } }
            }
        }
    }

    private var communityPicker: some View {
        List {
            Section("Choose a community") {
                Text("Understand who can help, then follow decisions before they happen.")
                Button("Explore Portland, Oregon") { store.selectCommunity() }
                    .accessibilityIdentifier("civic.choosePortland")
            }
            Section("Limited pilot") {
                Text(
                    "Portland is the only supported community. Choosing it does not confirm your address, school district, or service provider. ZIP codes do not establish jurisdiction."
                )
                Text("Elsewhere? Start with your city, county, school district, or transit agency’s official website.")
                Link(
                    "Find local government websites", destination: URL(string: "https://www.usa.gov/local-governments")!
                )
            }
        }
    }

    private func guide(now: Date) -> some View {
        List {
            Section {
                Text(store.catalog?.communityName ?? "Portland, Oregon").font(.headline)
                Text(store.catalog?.coverage ?? "The guide is currently unavailable.")
                Text(store.message).font(.footnote).foregroundStyle(Vote4UTheme.supportingText)
                Button(store.refreshing ? "Refreshing…" : "Refresh guide") {
                    Task { await store.refresh() }
                }
                .disabled(store.refreshing)
            }
            if let catalog = store.catalog {
                Section("Who can actually fix this?") {
                    TextField("Search concerns, e.g. bus or crossing", text: $query)
                        .accessibilityIdentifier("civic.search")
                    let topics = catalog.topics.filter { $0.matches(query) }
                    if topics.isEmpty {
                        Text("No reviewed guide matches. Try another topic or use the official agency directory.")
                        Link("Portland agencies", destination: URL(string: "https://www.portland.gov/bureaus")!)
                    }
                    ForEach(topics) { topic in
                        NavigationLink {
                            CivicTopicView(topicID: topic.id, store: store)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(topic.title).font(.headline)
                                Text(topic.body).font(.subheadline).foregroundStyle(Vote4UTheme.supportingText)
                                if store.followed.contains(topic.id) {
                                    Label("Following", systemImage: "bookmark.fill").font(.caption)
                                }
                            }
                        }
                        .accessibilityIdentifier("civic.topic.\(topic.id)")
                    }
                }
                Section("Before they vote") {
                    Toggle("Following only", isOn: $followingOnly)
                    Toggle("Include past meetings and outcomes", isOn: $showPast)
                    Text(
                        "Follow a concern to collect its reviewed updates here. Refresh when you open the app. No background alerts are sent."
                    )
                    .font(.footnote)
                    let items = catalog.decisions.filter {
                        (!followingOnly || store.followed.contains($0.topicID)) && (showPast || $0.meetingAt > now)
                    }.sorted { $0.meetingAt < $1.meetingAt }
                    if items.isEmpty {
                        Text(
                            followingOnly && store.followed.isEmpty
                                ? "Follow a concern above to build your list."
                                : "No reviewed decisions in this view. This does not mean nothing is scheduled; check the official agenda."
                        )
                    }
                    ForEach(items) { item in
                        NavigationLink {
                            CivicDecisionView(decisionID: item.id, store: store)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.title).font(.headline)
                                Text(item.formatted(item.meetingAt)).font(.subheadline)
                                Text(item.statusLabel(at: now)).font(.caption)
                            }
                        }
                        .accessibilityIdentifier("civic.decision.\(item.id)")
                    }
                }
            }
            Section {
                Link("Official Council agenda", destination: URL(string: "https://www.portland.gov/council/agenda")!)
                Text("Your community choice, search, and followed topics stay on this device.").font(.footnote)
            }
        }
        .refreshable { await store.refresh() }
    }
}
