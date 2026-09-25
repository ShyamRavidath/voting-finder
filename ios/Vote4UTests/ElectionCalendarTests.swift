import XCTest

@testable import Vote4U

/// `nextFederalElection()` drives both the countdown and the reminder schedule, and it is a
/// port of the web app's rule, so these cases mirror what the website must also produce.
final class ElectionCalendarTests: XCTestCase {
    private var calendar: Calendar { Calendar(identifier: .gregorian) }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testElectionIsTuesdayAfterFirstMondayInNovember() {
        // Nov 1 2026 is a Sunday, so the first Monday is the 2nd and Election Day is the 3rd.
        let election = ElectionCalendar.next(from: date(2026, 9, 20), calendar: calendar)
        XCTAssertEqual(election.date, date(2026, 11, 3))
        XCTAssertEqual(election.kind, "Midterm elections")
        XCTAssertEqual(election.daysAway, 44)
    }

    func testNovemberFirstOnAMondayMakesElectionTheSecond() {
        // Nov 1 2032 is a Monday — the boundary the modulo arithmetic most easily gets wrong.
        let election = ElectionCalendar.next(from: date(2032, 1, 1), calendar: calendar)
        XCTAssertEqual(election.date, date(2032, 11, 2))
    }

    func testRollsForwardOnceAnElectionHasPassed() {
        // The day after Election Day must jump to the next even year, not stay on a past date.
        let election = ElectionCalendar.next(from: date(2026, 11, 4), calendar: calendar)
        XCTAssertEqual(election.date, date(2028, 11, 7))
        XCTAssertEqual(election.kind, "Presidential election")
    }

    func testElectionDayItselfStillCountsAsUpcoming() {
        let election = ElectionCalendar.next(from: date(2026, 11, 3), calendar: calendar)
        XCTAssertEqual(election.date, date(2026, 11, 3))
        XCTAssertEqual(election.daysAway, 0)
    }

    func testOddYearsAreSkipped() {
        let election = ElectionCalendar.next(from: date(2027, 3, 1), calendar: calendar)
        XCTAssertEqual(election.date, date(2028, 11, 7))
    }

    func testPresidentialEveryFourYearsOtherwiseMidterm() {
        XCTAssertEqual(ElectionCalendar.next(from: date(2028, 1, 1), calendar: calendar).kind, "Presidential election")
        XCTAssertEqual(ElectionCalendar.next(from: date(2030, 1, 1), calendar: calendar).kind, "Midterm elections")
    }
}
