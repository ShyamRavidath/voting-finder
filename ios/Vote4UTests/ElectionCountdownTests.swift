import XCTest
@testable import Vote4U

/// The logic behind the Home Screen widget.
///
/// It lives in the app target rather than in `Vote4UWidgets` on purpose: a test bundle cannot
/// import an app extension, so anything that hides in the widget is a thing that never gets a
/// test. The widget itself is then a thin view over this.
final class ElectionCountdownTests: XCTestCase {
    private var calendar: Calendar { Calendar(identifier: .gregorian) }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func election(from day: Date) -> FederalElection {
        ElectionCalendar.next(from: day, calendar: calendar)
    }

    // MARK: - Phrasing

    func testCountdownPhraseHandlesTheTwoDaysThatMatter() {
        // "0 days" is wrong on the one day the whole app exists for, and "1 days" is just wrong.
        XCTAssertEqual(election(from: date(2026, 11, 3)).countdownPhrase, "Today")
        XCTAssertEqual(election(from: date(2026, 11, 2)).countdownPhrase, "Tomorrow")
        XCTAssertEqual(election(from: date(2026, 11, 1)).countdownPhrase, "2 days")
    }

    func testShortKindFitsATinyWidgetAndFollowsTheYear() {
        XCTAssertEqual(election(from: date(2026, 9, 21)).shortKind(calendar: calendar), "Midterms")
        XCTAssertEqual(election(from: date(2028, 1, 1)).shortKind(calendar: calendar), "Presidential")
    }

    func testPresidentialIsDerivedFromTheDateNotTheKindString() {
        // `kind` and `isPresidential` must never disagree, whichever way the wording changes.
        for start in [date(2026, 9, 21), date(2028, 1, 1), date(2030, 5, 5), date(2032, 1, 1)] {
            let next = election(from: start)
            XCTAssertEqual(
                next.isPresidential(calendar: calendar),
                next.kind == "Presidential election",
                "disagreement for \(next.date)"
            )
        }
    }

    func testSpokenSummaryNeverReadsABareNumber() {
        let today = election(from: date(2026, 11, 3)).spokenSummary(calendar: calendar)
        XCTAssertTrue(today.contains("is today"), today)
        XCTAssertTrue(today.contains("Midterm elections"), today)

        let soon = election(from: date(2026, 11, 1)).spokenSummary(calendar: calendar)
        XCTAssertTrue(soon.contains("is in 2 days"), soon)
    }

    // MARK: - Timeline

    func testRefreshDatesStartAtNowThenLandOnLocalMidnights() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 21, hour: 14, minute: 30))!
        let dates = ElectionCalendar.countdownRefreshDates(from: now, count: 7, calendar: calendar)

        XCTAssertEqual(dates.count, 8, "now, plus one entry per midnight")
        XCTAssertEqual(dates.first, now, "the widget must be right the moment it is added")

        for date in dates.dropFirst() {
            XCTAssertEqual(calendar.startOfDay(for: date), date, "\(date) is not a local midnight")
        }
        XCTAssertEqual(dates[1], self.date(2026, 9, 22))
        XCTAssertEqual(dates.last, self.date(2026, 9, 28))
    }

    func testRefreshDatesAreStrictlyIncreasing() {
        let now = Date()
        let dates = ElectionCalendar.countdownRefreshDates(from: now, count: 7, calendar: calendar)
        XCTAssertEqual(dates, dates.sorted())
        XCTAssertEqual(Set(dates).count, dates.count, "a repeated entry date would drop a day")
    }

    func testEachRefreshDateCountsDownFromItsOwnDay() {
        // The bug this guards: building the timeline once and reusing a single day count, which
        // freezes the widget at whatever number it showed when it was added.
        let now = date(2026, 9, 21)
        let counts = ElectionCalendar
            .countdownRefreshDates(from: now, count: 7, calendar: calendar)
            .map { election(from: $0).daysAway }

        XCTAssertEqual(counts, [43, 42, 41, 40, 39, 38, 37, 36])
    }

    func testRefreshDatesDegradeSafelyOnAZeroCount() {
        let now = Date()
        XCTAssertEqual(ElectionCalendar.countdownRefreshDates(from: now, count: 0, calendar: calendar), [now])
    }
}
