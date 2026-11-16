import SwiftUI

struct CivicTopicView: View {
    let topicID: String
    let store: CivicStore

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
                            "This guide needs a source recheck. Confirm responsibility with the agency.",
                            systemImage: "exclamationmark.triangle")
                    }
                    Button(
                        store.followed.contains(topic.id) ? "Unfollow topic" : "Follow topic",
                        systemImage: store.followed.contains(topic.id) ? "bookmark.fill" : "bookmark"
                    ) {
                        store.toggleFollow(topic.id)
                    }
                    .accessibilityIdentifier("civic.follow")
                    Text("Following collects reviewed decisions in your local feed. No background alerts.").font(
                        .footnote)
                }
                Section("Who is responsible?") {
                    Text(topic.body).font(.headline)
                    Text(topic.authority)
                }
                Section("How a decision happens") { Text(topic.process) }
                Section("Your next step") { Link(topic.action, destination: topic.actionURL) }
                Section("Related decisions") {
                    let decisions = store.catalog?.decisions.filter { $0.topicID == topic.id } ?? []
                    if decisions.isEmpty {
                        Text(
                            "No reviewed agenda item is available for this topic. Check the agency’s meeting page for current opportunities."
                        )
                    }
                    ForEach(decisions) { decision in
                        NavigationLink(decision.title) { CivicDecisionView(decisionID: decision.id, store: store) }
                            .accessibilityIdentifier("civic.related.\(decision.id)")
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
