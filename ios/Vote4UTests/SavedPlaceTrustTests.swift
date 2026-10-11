import XCTest

@testable import Vote4U

final class SavedPlaceTrustTests: XCTestCase {
    private func location(estimated: Bool?) -> PollingLocation {
        PollingLocation(
            name: "Beverly Hills Public Library", addr: "444 N Rexford Dr", type: "Civic Building",
            lat: nil, lng: nil, distance: nil, isEstimated: estimated
        )
    }

    func testSavedUnconfirmedLocationKeepsEvidenceAfterRelaunch() throws {
        let saved = SavedPlace(location: location(estimated: true))
        let restored = try JSONDecoder().decode(SavedPlace.self, from: JSONEncoder().encode(saved))
        XCTAssertFalse(restored.isConfirmed)
        XCTAssertEqual(restored.type, "Civic Building")
        XCTAssertTrue(restored.confirmationNotice.contains("Not confirmed"))
    }

    func testLegacySavedLocationDoesNotGainConfirmation() throws {
        let data = Data(#"{"name":"Library","addr":"Address","savedAt":0}"#.utf8)
        let saved = try JSONDecoder().decode(SavedPlace.self, from: data)
        XCTAssertFalse(saved.isConfirmed)
        XCTAssertTrue(saved.confirmationNotice.contains("Not confirmed"))
    }

    func testMissingAPIEvidenceDoesNotMeanOfficial() {
        XCTAssertFalse(location(estimated: nil).isConfirmed)
        XCTAssertTrue(location(estimated: nil).shareText.contains("Not confirmed"))
    }

    func testSharedCivicBuildingIncludesWarningAndOfficialLookup() {
        let shared = location(estimated: true).shareText
        XCTAssertTrue(shared.contains("Civic Building"))
        XCTAssertTrue(shared.contains("Not confirmed"))
        XCTAssertTrue(shared.contains("https://www.usa.gov/find-polling-place"))
    }

    func testOfficialAPIPayloadUsesRealEvidence() throws {
        let data = Data(#"{"name":"Library","addr":"Address","type":"Polling Place","isReal":true}"#.utf8)
        let decoded = try JSONDecoder().decode(PollingLocation.self, from: data)
        XCTAssertTrue(decoded.isConfirmed)
        XCTAssertTrue(SavedPlace(location: decoded).isConfirmed)
    }

    func testExplicitOfficialEvidenceSurvivesSaving() throws {
        let saved = SavedPlace(location: location(estimated: false))
        let restored = try JSONDecoder().decode(SavedPlace.self, from: JSONEncoder().encode(saved))
        XCTAssertTrue(restored.isConfirmed)
    }
}
