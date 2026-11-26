import Foundation
import Observation

@MainActor @Observable
final class CivicFeedStore {
    private(set) var feed: CivicFeed?
    private(set) var followedMeetings: [String: CivicMeeting] = [:]
    private(set) var refreshing = false
    private(set) var message = "Saved copy. Pull down to update."
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let fetch: () async throws -> Data

    init(
        defaults: UserDefaults = .standard,
        fetch: @escaping () async throws -> Data = { try await CivicFeedStore.fetchFeed() }
    ) {
        self.defaults = defaults
        self.fetch = fetch
        feed = try? CivicFeed.bundled().savedCopy
        if let data = defaults.data(forKey: "civic.liveFeed"), let cached = try? CivicFeed.decode(data) {
            merge(cached.savedCopy)
        }
        if let data = defaults.data(forKey: "civic.meetings"),
            let saved = try? JSONDecoder().decode([String: CivicMeeting].self, from: data)
        {
            followedMeetings = saved
        }
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-civicCalendarTest"), let current = feed {
                let meeting = CivicMeeting(
                    id: "/debug-calendar", title: "DEBUG Civic Calendar Fixture", summary: "Simulator test only.",
                    url: URL(string: "https://www.portland.gov/council/agenda")!,
                    startsAt: Date().addingTimeInterval(172_800), endsAt: Date().addingTimeInterval(176_400),
                    status: "scheduled", online: true)
                feed = CivicFeed(
                    schemaVersion: 1, services: current.services,
                    meetings: CivicFeedSection(fetchedAt: .now, source: "saved", items: [meeting]),
                    actions: current.actions)
            }
        #endif
        updateFollowedRecords()
    }

    func toggleFollow(_ meeting: CivicMeeting) {
        if followedMeetings[meeting.id] != nil {
            followedMeetings.removeValue(forKey: meeting.id)
        } else {
            followedMeetings[meeting.id] = meeting
        }
        saveFollowing()
    }

    func meeting(_ id: String) -> CivicMeeting? {
        feed?.meetings.items.first { $0.id == id } ?? followedMeetings[id]
    }

    func refresh() async {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }
        do {
            let updated = try CivicFeed.decode(try await fetch())
            merge(updated)
            updateFollowedRecords()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let feed, let data = try? encoder.encode(feed) { defaults.set(data, forKey: "civic.liveFeed") }
            let saved = [feed?.services.source, feed?.meetings.source, feed?.actions.source].contains("saved")
            message =
                saved
                ? "Some city pages couldn’t be updated. Showing saved details."
                : "Checked the city’s published pages."
        } catch {
            feed = feed?.savedCopy
            message = "Couldn’t refresh. Showing saved details."
        }
    }

    private func merge(_ updated: CivicFeed) {
        guard var current = feed else {
            feed = updated
            return
        }
        if updated.services.fetchedAt >= current.services.fetchedAt {
            current.services = updated.services
        } else {
            current.services.source = "saved"
        }
        if updated.meetings.fetchedAt >= current.meetings.fetchedAt {
            current.meetings = updated.meetings
        } else {
            current.meetings.source = "saved"
        }
        if updated.actions.fetchedAt >= current.actions.fetchedAt {
            current.actions = updated.actions
        } else {
            current.actions.source = "saved"
        }
        feed = current
    }

    private func updateFollowedRecords() {
        for item in feed?.meetings.items ?? [] where followedMeetings[item.id] != nil {
            followedMeetings[item.id] = item
        }
        saveFollowing()
    }

    private func saveFollowing() {
        if let data = try? JSONEncoder().encode(followedMeetings) { defaults.set(data, forKey: "civic.meetings") }
    }

    nonisolated private static func fetchFeed() async throws -> Data {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-civicOffline") { throw APIError.offline }
        #endif
        var request = URLRequest(
            url: APIClient.shared.baseURL.appendingPathComponent("api/local-feed"),
            cachePolicy: .reloadIgnoringLocalCacheData)
        request.timeoutInterval = 28
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.offline }
        return data
    }
}
