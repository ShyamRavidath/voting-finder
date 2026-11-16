import XCTest

@testable import Vote4U

final class CivicCatalogTests: XCTestCase {
    private func data() throws -> Data {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "local-civic", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    private func changed(_ edit: (inout [String: Any]) -> Void) throws -> Data {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data()) as? [String: Any])
        edit(&json)
        return try JSONSerialization.data(withJSONObject: json)
    }

    func testBundledGuideHasLinkedDecisionsAndConservativeTimeBoundaries() throws {
        let catalog = try CivicCatalog.bundled()
        XCTAssertEqual(catalog.topics.count, 3)
        XCTAssertEqual(catalog.decisions.count, 2)
        let item = try XCTUnwrap(catalog.decisions.first)
        XCTAssertTrue(item.canSaveCalendar(at: item.checkedAt))
        XCTAssertFalse(item.canSaveCalendar(at: item.checkedAt.addingTimeInterval(-1)))
        XCTAssertFalse(item.canSaveCalendar(at: item.meetingAt))
        XCTAssertFalse(item.canSaveCalendar(at: item.reviewBy))
        XCTAssertEqual(item.statusLabel(at: item.meetingAt), "Meeting time passed — outcome not verified")
        XCTAssertEqual(item.statusLabel(at: item.reviewBy), "Needs a source recheck")
        XCTAssertTrue(catalog.topics.contains { $0.matches("BUS") })
        XCTAssertFalse(catalog.topics.contains { $0.matches("unknown concern xyz") })
    }

    func testRejectsUnsupportedCommunityUnknownTopicAndUntrustedSources() throws {
        XCTAssertThrowsError(try CivicCatalog.decode(changed { $0["communityID"] = "other-city" }))
        XCTAssertThrowsError(try CivicCatalog.decode(changed { $0["schemaVersion"] = 99 }))
        for field in ["topicID", "sources", "reviewBy", "status", "commentDeadline"] {
            let malformed = try changed { json in
                var items = json["decisions"] as! [[String: Any]]
                switch field {
                case "topicID": items[0][field] = "unsupported"
                case "sources":
                    items[0][field] = [["title": "False authority", "url": "https://www.portland.gov.evil.test"]]
                case "reviewBy": items[0][field] = "2027-11-15T03:00:00Z"
                case "status": items[0][field] = "decided"  // no sourced outcome
                default: items[0][field] = "2027-11-15T03:00:00Z"
                }
                json["decisions"] = items
            }
            XCTAssertThrowsError(try CivicCatalog.decode(malformed), field)
        }
    }

    func testCancelledAndPostponedItemsCannotBecomeCalendarEvents() throws {
        for status in ["cancelled", "postponed"] {
            let catalog = try CivicCatalog.decode(
                changed { json in
                    var items = json["decisions"] as! [[String: Any]]
                    items[0]["status"] = status
                    json["decisions"] = items
                })
            let item = catalog.decisions[0]
            XCTAssertFalse(item.canSaveCalendar(at: item.checkedAt))
        }
    }

    func testSourcedOutcomeIsRetainedWithoutClaimingCompletion() throws {
        let catalog = try CivicCatalog.decode(
            changed { json in
                var items = json["decisions"] as! [[String: Any]]
                items[0]["status"] = "decided"
                items[0]["outcome"] = [
                    "summary": "Test record: approved; implementation not verified.",
                    "recordedAt": items[0]["checkedAt"]!,
                    "source": ["title": "Decision record", "url": "https://www.portland.gov/council/documents"],
                ]
                json["decisions"] = items
            })
        let item = catalog.decisions[0]
        XCTAssertEqual(item.statusLabel(at: item.checkedAt), "Outcome recorded")
        XCTAssertFalse(item.canSaveCalendar(at: item.checkedAt))
        XCTAssertTrue(item.outcome?.summary.contains("implementation not verified") == true)
    }

    @MainActor
    func testFollowsPersistAndFailedRefreshKeepsSavedEvidence() async throws {
        let name = "CivicTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let payload = try data()
        let store = CivicStore(defaults: defaults, fetch: { payload })
        store.selectCommunity()
        store.toggleFollow("transit")
        store.toggleFollow("made-up-topic")
        await store.refresh()
        XCTAssertNotNil(defaults.data(forKey: "civic.catalog"))
        let restored = CivicStore(defaults: defaults, fetch: { throw APIError.offline })
        XCTAssertTrue(restored.communitySelected)
        XCTAssertEqual(restored.followed, ["transit"])
        await restored.refresh()
        XCTAssertEqual(restored.catalog?.decisions.count, 2)
        XCTAssertTrue(restored.message.contains("Couldn’t refresh"))
        restored.toggleFollow("transit")
        XCTAssertTrue(CivicStore(defaults: defaults).followed.isEmpty)
        restored.changeCommunity()
        XCTAssertFalse(CivicStore(defaults: defaults).communitySelected)
    }

    @MainActor
    func testMalformedOlderOrFutureUpdateCannotReplaceCatalog() async throws {
        let name = "CivicTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let older = try changed { json in
            json["publishedAt"] = "2026-11-15T03:00:00Z"
            for key in ["topics", "decisions"] {
                var records = json[key] as! [[String: Any]]
                for index in records.indices { records[index]["checkedAt"] = "2026-11-15T03:00:00Z" }
                json[key] = records
            }
        }
        // Prove rollback protection is exercised, rather than just rejecting malformed data.
        XCTAssertNoThrow(try CivicCatalog.decode(older))
        let future = try changed {
            $0["publishedAt"] = ISO8601DateFormatter().string(from: Date().addingTimeInterval(86_400))
        }
        XCTAssertNoThrow(try CivicCatalog.decode(future))
        for payload in [Data("{}".utf8), older, future] {
            let store = CivicStore(defaults: defaults, fetch: { payload })
            store.selectCommunity()
            let before = store.catalog?.publishedAt
            await store.refresh()
            XCTAssertEqual(store.catalog?.publishedAt, before)
            XCTAssertNil(defaults.data(forKey: "civic.catalog"))
        }
    }
}
