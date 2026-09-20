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

    func testDecodesTheRealArticleShape() throws {
        // Field names must match server/services/newsService.js. They silently did not once
        // already, and because every field is optional it decoded fine and rendered blanks.
        let json = """
        {"articles":[{"id":"abc","candidate":"2028 Election","title":"Options in the 2028 race",
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
