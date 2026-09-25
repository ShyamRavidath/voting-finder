import UserNotifications
import XCTest

@testable import Vote4U

/// Runs in the Simulator against the real UNUserNotificationCenter, so it verifies that requests
/// are genuinely accepted and queued — not just that the date arithmetic is right.
///
/// What it cannot prove is that a banner appears on screen; that needs a real device and a human
/// granting permission. See HANDOFF's device-testing list.
final class ReminderSchedulerTests: XCTestCase {
    private var calendar: Calendar { Calendar(identifier: .gregorian) }
    private var center: UNUserNotificationCenter { .current() }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    override func setUp() async throws {
        try await super.setUp()
        // UNUserNotificationCenter refuses to queue anything unauthorized, which used to make
        // every assertion below skip — and a skip reads as a pass. Fail loudly instead, naming
        // the fix. `requestAuthorization` on an already-decided app returns the existing answer
        // without showing an alert, so this is safe to call in a unit test.
        let granted = await ReminderScheduler.authorize()
        try XCTSkipIf(
            !granted,
            """
            Notifications are not authorized on this simulator, so nothing can be queued and \
            these assertions would be vacuous. Run ./scripts/test-ios.sh, which taps Allow in a \
            UI test first — plain `xcodebuild test` cannot grant this.
            """
        )
    }

    override func tearDown() async throws {
        ReminderScheduler.cancelAll()
        try await super.tearDown()
    }

    private func pending() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func testSchedulesBothRemindersAtTheRightTimes() async throws {
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: date(2026, 9, 20))

        let requests = await pending()
        XCTAssertEqual(requests.count, 2)

        let triggers = requests.compactMap { ($0.identifier, $0.trigger as? UNCalendarNotificationTrigger) }
        for (id, trigger) in triggers {
            let components = try XCTUnwrap(trigger?.dateComponents)
            if id.contains("week-before") {
                // Election Day is Nov 3 2026, so a week earlier lands in October.
                XCTAssertEqual(components.month, 10)
                XCTAssertEqual(components.day, 27)
                XCTAssertEqual(components.hour, 9)
            } else {
                XCTAssertEqual(components.month, 11)
                XCTAssertEqual(components.day, 3)
                XCTAssertEqual(components.hour, 7)
            }
        }
    }

    func testTheMorningReminderNamesTheSavedPollingPlace() async throws {
        let saved = SavedPlace(
            location: PollingLocation(
                name: "Beverly Hills Public Library", addr: "444 N Rexford Dr",
                type: "Likely Polling Place", lat: nil, lng: nil, distance: nil, isEstimated: true
            )
        )
        await ReminderScheduler.schedule(place: saved, calendar: calendar, now: date(2026, 9, 20))

        let requests = await pending()
        let morning = try XCTUnwrap(requests.first { $0.identifier.contains("morning-of") })
        XCTAssertTrue(morning.content.body.contains("Beverly Hills Public Library"), morning.content.body)
    }

    func testReschedulingReplacesRatherThanStacks() async throws {
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: date(2026, 9, 20))
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: date(2026, 9, 20))

        let requests = await pending()
        XCTAssertEqual(requests.count, 2, "rescheduling must replace, never stack")
    }

    func testCancelAllClearsEverything() async throws {
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: date(2026, 9, 20))
        ReminderScheduler.cancelAll()

        // removePendingNotificationRequests is asynchronous inside the daemon.
        try await Task.sleep(nanoseconds: 300_000_000)
        let remaining = await pending()
        XCTAssertTrue(remaining.isEmpty, "found \(remaining.map(\.identifier))")
    }

    func testAWeekBeforeInThePastIsNotScheduled() async throws {
        // Six days out: the week-before reminder has already passed and must be skipped, leaving
        // only the morning-of one. Scheduling a trigger in the past would never fire.
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: date(2026, 10, 28))

        let requests = await pending()
        XCTAssertEqual(requests.count, 1)
        XCTAssertTrue(requests[0].identifier.contains("morning-of"))
    }
}
