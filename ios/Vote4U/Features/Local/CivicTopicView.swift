import SwiftUI

struct CivicTopicView: View {
    let topicID: String
    let store: CivicStore
    var feedStore: CivicFeedStore? = nil

    var body: some View {
        Group {
            if let topic = store.catalog?.topics.first(where: { $0.id == topicID }) {
                detail(topic)
            } else {
                ContentUnavailableView(
                    "Guide no longer listed", systemImage: "doc.text.magnifyingglass",
                    description: Text(
                        "This concern was removed from the updated guide. Check the agency’s official website."))
            }
        }
        .navigationTitle("Who can help?")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detail(_ topic: CivicTopic) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            List {
                Section {
                    Text(topic.title).font(.title2.bold())
                    Text("Source check: \(topic.checkedAt.formatted(date: .abbreviated, time: .omitted))").font(
                        .footnote)
                    if context.date >= topic.reviewBy || context.date < topic.checkedAt {
                        Label(
                            "This guide may be out of date. Open the agency link for current details.",
                            systemImage: "exclamationmark.triangle")
                    }
                    Button(
                        store.followed.contains(topic.id) ? "Remove saved guide" : "Save guide",
                        systemImage: store.followed.contains(topic.id) ? "bookmark.fill" : "bookmark"
                    ) {
                        store.toggleFollow(topic.id)
                    }
                    .accessibilityIdentifier("civic.follow")
                    Text("Find saved guides in Following. No notifications are sent.").font(
                        .footnote)
                }
                Section("Who is responsible?") {
                    Text(topic.body).font(.headline)
                    Text(topic.authority)
                }
                Section("How it works") { Text(topic.process) }
                Section("Contact the agency") { Link(topic.action, destination: topic.actionURL) }
                Section("Related decisions") {
                    let decisions = store.catalog?.decisions.filter { $0.topicID == topic.id } ?? []
                    if decisions.isEmpty {
                        Text(
                            "No related item in this feed. The agency link has its current meetings."
                        )
                    }
                    ForEach(decisions) { decision in
                        if let action = feedStore?.feed?.actions.items.first(where: { $0.id == decision.id }) {
                            NavigationLink(action.displayTitle) { CivicActionView(action: action) }
                        } else {
                            Link(decision.title, destination: decision.sources.first!.url)
                        }
                    }
                }
                CivicSourcesView(
                    checkedAt: topic.checkedAt, reviewBy: topic.reviewBy, sources: topic.sources, now: context.date)
            }
        }
        .navigationTitle("Who can help?")
        .navigationBarTitleDisplayMode(.inline)
    }
}
