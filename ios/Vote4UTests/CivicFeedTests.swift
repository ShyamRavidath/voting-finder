import XCTest

@testable import Vote4U

final class CivicFeedTests: XCTestCase {
    private func data(_ mutate: (inout [String: Any]) -> Void = { _ in }) throws -> Data {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "local-feed", withExtension: "json"))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        mutate(&json)
        return try JSONSerialization.data(withJSONObject: json)
    }

    func testRealDirectorySearchHandlesDrugsAndOrdinaryLanguage() throws {
        let feed = try CivicFeed.bundled()
        XCTAssertEqual(feed.services.items.count, 567)
        let drug = try XCTUnwrap(feed.services.items.first { $0.id == "/police/drug-complaint" })
        XCTAssertGreaterThan(drug.searchScore("drugs"), 0)
        XCTAssertGreaterThan(drug.searchScore("I'm having issues with drugs"), 0)
        XCTAssertGreaterThan(drug.searchScore("DRUG"), 0)
        XCTAssertEqual(drug.searchScore("zzxxyy"), 0)
        XCTAssertGreaterThan(feed.meetings.items.count, 20)
        XCTAssertEqual(feed.actions.items.first { $0.id == "2026-401" }?.action, "Passed to second reading")
    }

    func testMalformedFutureAndUntrustedFeedRejected() throws {
        for mode in ["future", "url", "duplicate", "status", "end", "video"] {
            let payload = try data { json in
                var services = json["services"] as! [String: Any]
                var items = services["items"] as! [[String: Any]]
                if mode == "future" { services["fetchedAt"] = "2099-01-01T00:00:00Z" }
                if mode == "url" { items[0]["url"] = "https://www.portland.gov.evil.test/services" }
                if mode == "duplicate" { items.append(items[0]) }
                services["items"] = items
                json["services"] = services
                var meetings = json["meetings"] as! [String: Any]
                var records = meetings["items"] as! [[String: Any]]
                if mode == "status" { records[0]["status"] = "confirmed" }
                if mode == "end" { records[0]["endsAt"] = "2000-01-01T00:00:00Z" }
                meetings["items"] = records
                json["meetings"] = meetings
                if mode == "video" {
                    var actions = json["actions"] as! [String: Any]
                    var records = actions["items"] as! [[String: Any]]
                    records[0]["videoURL"] = "https://www.youtube.com.evil.test/watch?v=1"
                    actions["items"] = records
                    json["actions"] = actions
                }
            }
            XCTAssertThrowsError(try CivicFeed.decode(payload), mode)
        }
    }

    func testCalendarRequiresRecentListedFutureMeetingAndHonorsCancellation() throws {
        let feed = try CivicFeed.bundled()
        let item = try XCTUnwrap(feed.meetings.items.first { $0.startsAt > feed.meetings.fetchedAt })
        let now = item.startsAt.addingTimeInterval(-3600)
        XCTAssertTrue(item.canSave(at: now, fetchedAt: now, listed: true))
        XCTAssertFalse(item.canSave(at: now, fetchedAt: now, listed: false))
        XCTAssertFalse(item.canSave(at: now, fetchedAt: now.addingTimeInterval(-86_400), listed: true))
        XCTAssertFalse(item.canSave(at: item.startsAt, fetchedAt: now, listed: true))
        XCTAssertFalse(item.canSave(at: now, fetchedAt: now.addingTimeInterval(1), listed: true))
        let cancelled = CivicMeeting(
            id: item.id, title: item.title, summary: item.summary, url: item.url,
            startsAt: item.startsAt, endsAt: item.endsAt, status: "cancelled", online: item.online)
        XCTAssertFalse(cancelled.canSave(at: now, fetchedAt: now, listed: true))
    }

    @MainActor
    func testFollowingSurvivesRelaunchOutageAndRollingCalendar() async throws {
        let suite = "CivicFeedTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = try CivicFeed.bundled()
        let item = try XCTUnwrap(original.meetings.items.first)
        let payload = try data { json in
            var section = json["meetings"] as! [String: Any]
            section["items"] = []
            json["meetings"] = section
        }
        let store = CivicFeedStore(defaults: defaults, fetch: { payload })
        store.toggleFollow(item)
        await store.refresh()
        XCTAssertEqual(store.meeting(item.id), item)
        XCTAssertFalse(store.feed!.meetings.items.contains { $0.id == item.id })
        let restored = CivicFeedStore(defaults: defaults, fetch: { throw APIError.offline })
        XCTAssertEqual(restored.followedMeetings[item.id], item)
        await restored.refresh()
        XCTAssertTrue(restored.message.contains("Couldn’t refresh"))
        XCTAssertEqual(restored.feed?.meetings.fetchedAt, original.meetings.fetchedAt)
        restored.toggleFollow(item)
        XCTAssertTrue(CivicFeedStore(defaults: defaults).followedMeetings.isEmpty)
    }

    @MainActor
    func testRollbackCannotReplaceNewerSections() async throws {
        let suite = "CivicFeedTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let payload = try data { json in
            for key in ["services", "meetings", "actions"] {
                var section = json[key] as! [String: Any]
                section["fetchedAt"] = "2020-01-01T00:00:00Z"
                section["items"] = []
                json[key] = section
            }
        }
        let store = CivicFeedStore(defaults: defaults, fetch: { payload })
        let before = store.feed?.services.fetchedAt
        await store.refresh()
        XCTAssertEqual(store.feed?.services.fetchedAt, before)
        XCTAssertEqual(store.feed?.services.items.count, 567)
    }
}
