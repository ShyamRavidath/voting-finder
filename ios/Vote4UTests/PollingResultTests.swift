import XCTest
@testable import Vote4U

final class PollingResultTests: XCTestCase {
    private func location(isEstimated: Bool?, distance: Double? = nil) -> PollingLocation {
        PollingLocation(
            name: "Test Library", addr: "1 Main St", type: "Likely Polling Place",
            lat: nil, lng: nil, distance: distance, isEstimated: isEstimated
        )
    }

    func testOnlyOfficialResultsCountAsConfirmed() {
        // The rule the whole codebase is built around: never present an estimate as confirmed.
        XCTAssertFalse(location(isEstimated: true).isConfirmed)
        XCTAssertTrue(location(isEstimated: false).isConfirmed)
        XCTAssertTrue(location(isEstimated: nil).isConfirmed, "official results omit the flag")
    }

    func testMilesConversionAndPrecision() {
        XCTAssertEqual(location(isEstimated: true, distance: 1.0).milesAway, "0.6 mi")
        XCTAssertEqual(location(isEstimated: true, distance: 32.2).milesAway, "20 mi")
        XCTAssertNil(location(isEstimated: true, distance: nil).milesAway)
    }

    func testDecodesTheRealAPIShape() throws {
        // Captured from https://vote4ucyl.vercel.app/api/polling?zip=90210 — note `distance`
        // arrives as an integer, which must still decode into a Double.
        let json = """
        {"locations":[{"name":"Beverly Hills Public Library","addr":"North Rexford Drive, Beverly Hills, California, 90210","type":"Likely Polling Place","lat":34.072877,"lng":-118.3991019,"distance":2,"isReal":true,"isEstimated":true}],
         "place":{"city":"Beverly Hills","state":"California","stateAbbr":"CA","zip":"90210","lat":34.0901,"lng":-118.4065},
         "zip":"90210","dataSource":"estimated","cached":false}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(PollingResult.self, from: json)
        XCTAssertEqual(result.zip, "90210")
        XCTAssertEqual(result.place?.stateAbbr, "CA")
        XCTAssertEqual(result.locations.first?.distance, 2)
        XCTAssertFalse(result.isOfficial)
        XCTAssertFalse(result.locations[0].isConfirmed)
    }

    func testDecodesTheWidenedTier() throws {
        // Captured live from /api/polling?zip=83428 on 2026-09-21 — a ZIP where the tight search
        // finds nothing and the server widens. `searchRadiusKm` is the new field; pinning a real
        // payload is how the last silent field-name mismatch would have been caught.
        let json = """
        {"locations":[{"name":"Swan Valley Elementary School","addr":"Swan Valley Highway, Irwin, Idaho, 83428","type":"Civic Building","lat":43.4057955,"lng":-111.2932119,"distance":3.9,"isReal":true,"isEstimated":true}],
         "place":{"city":"Irwin","state":"Idaho","stateAbbr":"ID","zip":"83428","lat":43.3861,"lng":-111.2527},
         "election":null,"searchRadiusKm":25,"zip":"83428","device":null,"dataSource":"nearby","cached":false}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(PollingResult.self, from: json)
        XCTAssertTrue(result.isWidened)
        XCTAssertFalse(result.isOfficial)
        XCTAssertEqual(result.searchRadiusKm, 25)
        XCTAssertEqual(result.searchRadiusMiles, 16)
        // The weakest tier must still label every venue unconfirmed.
        XCTAssertFalse(result.locations.allSatisfy(\.isConfirmed))
        XCTAssertEqual(result.locations.first?.type, "Civic Building")
    }

    func testTierFlagsAreMutuallyExclusive() throws {
        // An older cached payload predates `searchRadiusKm`; it must still decode.
        let json = """
        {"locations":[],"place":null,"zip":"19901","dataSource":"none"}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(PollingResult.self, from: json)
        XCTAssertNil(result.searchRadiusKm)
        XCTAssertNil(result.searchRadiusMiles)
        XCTAssertFalse(result.isOfficial)
        XCTAssertFalse(result.isWidened)
        XCTAssertTrue(result.isEmpty)
    }

    func testDecodesTheRealArticleShape() throws {
        // Field names must match server/services/newsService.js. They silently did not once
        // already, and because every field is optional it decoded fine and rendered blanks.
        let json = """
        {"articles":[{"id":"abc","candidate":"Gavin Newsom","title":"Options in the 2028 race",
         "excerpt":null,"date":"2026-09-20T06:50:00.000Z","source":"Gazette",
         "url":"https://example.com/a","category":"election","party":null,"imageUrl":null}]}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(NewsResponse.self, from: json)
        let article = try XCTUnwrap(response.articles.first)
        XCTAssertEqual(article.source, "Gazette")
        XCTAssertEqual(article.date, "2026-09-20T06:50:00.000Z")
        XCTAssertFalse(Formatting.timeAgo(article.date).isEmpty, "date must actually parse")
    }
}
