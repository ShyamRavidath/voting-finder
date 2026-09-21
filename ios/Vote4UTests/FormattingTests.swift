import XCTest
@testable import Vote4U

final class FormattingTests: XCTestCase {
    private let now = try! Date.ISO8601FormatStyle().parse("2026-09-20T12:00:00Z")

    private func ago(_ iso: String) -> String {
        Formatting.timeAgo(iso, now: now)
    }

    func testRelativeBucketsMatchTheWebApp() {
        XCTAssertEqual(ago("2026-09-20T11:59:30Z"), "Just now")
        XCTAssertEqual(ago("2026-09-20T11:30:00Z"), "30 min ago")
        XCTAssertEqual(ago("2026-09-20T09:00:00Z"), "3 hr ago")
        XCTAssertEqual(ago("2026-09-19T09:00:00Z"), "1 day ago")
        XCTAssertEqual(ago("2026-09-17T09:00:00Z"), "3 days ago")
    }

    func testSingularDay() {
        XCTAssertEqual(ago("2026-09-19T11:00:00Z"), "1 day ago")
    }

    func testOlderThanAWeekFallsBackToADate() {
        let result = ago("2026-08-01T09:00:00Z")
        XCTAssertFalse(result.hasSuffix("ago"), "expected an absolute date, got \(result)")
        XCTAssertFalse(result.isEmpty)
    }

    func testMissingOrUnparseableDatesReturnEmpty() {
        XCTAssertEqual(Formatting.timeAgo(nil, now: now), "")
        XCTAssertEqual(Formatting.timeAgo("not a date", now: now), "")
    }

    func testHandlesFractionalSecondsWhichTheNewsAPISends() {
        // The API sends "2026-09-20T06:50:00.000Z"; the plain ISO8601 formatter rejects that.
        XCTAssertEqual(ago("2026-09-20T09:00:00.000Z"), "3 hr ago")
    }
}
