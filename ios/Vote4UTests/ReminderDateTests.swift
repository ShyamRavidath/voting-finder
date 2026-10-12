import UserNotifications
import XCTest

@testable import Vote4U

final class ReminderDateTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testHistoricalBoundariesAndNextElectionRollover() throws {
        let cases: [(Date, [Int], Int)] = [
            (date(2026, 9, 20), [9, 7], 2026),
            (date(2026, 10, 27, 9), [7], 2026),
            (date(2026, 11, 3, 7), [], 2026),
            (date(2026, 11, 4), [9, 7], 2028),
        ]
        for (now, hours, year) in cases {
            let requests = ReminderScheduler.requests(place: nil, calendar: calendar, now: now)
            let components = try requests.map {
                try XCTUnwrap(($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents)
            }
            XCTAssertEqual(components.map(\.hour), hours.map(Optional.some))
            XCTAssertTrue(components.allSatisfy { $0.year == year })
        }
    }

    func testHomeScheduleUsesLocalMidnightAcrossDSTAndElectionDay() {
        var entries = ElectionCountdownSchedule(calendar: calendar)
            .entries(from: date(2026, 10, 31, 23), mode: .normal)
        XCTAssertEqual(entries.next(), date(2026, 10, 31, 23))
        XCTAssertEqual(entries.next(), date(2026, 11, 1))
        XCTAssertEqual(entries.next(), date(2026, 11, 2))
        XCTAssertEqual(entries.next(), date(2026, 11, 3))
        let election = ElectionCalendar.next(from: date(2026, 11, 3), calendar: calendar)
        XCTAssertEqual(election.circularCountdown.value, "Today")
        XCTAssertNil(election.circularCountdown.unit)
        XCTAssertTrue(election.spokenSummary().contains("is today"))
        XCTAssertTrue(
            ElectionCalendar.next(from: date(2026, 11, 2), calendar: calendar)
                .spokenSummary().contains("is tomorrow"))
    }
}
