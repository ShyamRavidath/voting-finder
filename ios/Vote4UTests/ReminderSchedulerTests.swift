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
    // Keep actual queued triggers well ahead of the OS clock, even after Election Day 2026.
    private var futureStart: Date {
        let year = calendar.component(.year, from: Date()) + 2
        return date(year, 1, 1)
    }
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
        XCTAssertTrue(
            granted,
            """
            Notifications are not authorized on this simulator, so nothing can be queued and \
            these assertions would be vacuous. Run ./scripts/test-ios.sh, which taps Allow in a \
            UI test first — plain `xcodebuild test` cannot grant this.
            """
        )
    }

    override func tearDown() async throws {
        await ReminderScheduler.cancelPending()
        try await super.tearDown()
    }

    private func pending() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func testSchedulesBothRemindersAtTheRightTimes() async throws {
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: futureStart)

        let requests = await pending()
        XCTAssertEqual(requests.count, 2)

        let triggers = requests.compactMap { ($0.identifier, $0.trigger as? UNCalendarNotificationTrigger) }
        for (id, trigger) in triggers {
            let components = try XCTUnwrap(trigger?.dateComponents)
            if id.contains("week-before") {
                let election = ElectionCalendar.next(from: futureStart, calendar: calendar)
                let expected = calendar.date(byAdding: .day, value: -7, to: election.date)!
                XCTAssertEqual(components.year, calendar.component(.year, from: expected))
                XCTAssertEqual(components.month, calendar.component(.month, from: expected))
                XCTAssertEqual(components.day, calendar.component(.day, from: expected))
                XCTAssertEqual(components.hour, 9)
            } else {
                XCTAssertEqual(components.month, 11)
                XCTAssertEqual(
                    components.day,
                    calendar.component(.day, from: ElectionCalendar.next(from: futureStart, calendar: calendar).date))
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
        await ReminderScheduler.schedule(place: saved, calendar: calendar, now: futureStart)

        let requests = await pending()
        let morning = try XCTUnwrap(requests.first { $0.identifier.contains("morning-of") })
        XCTAssertTrue(morning.content.body.contains("Beverly Hills Public Library"), morning.content.body)
        XCTAssertTrue(morning.content.body.contains("Not confirmed"), morning.content.body)
        XCTAssertEqual(morning.content.title, "Today is Election Day")
    }

    @MainActor
    func testSavingAndRemovingAPlaceRespectDisabledReminders() async throws {
        let defaults = UserDefaults.standard
        let previousSetting = defaults.object(forKey: "remindersEnabled")
        let previousPlace = SavedPlaceStore.load()
        defer {
            if let previousSetting {
                defaults.set(previousSetting, forKey: "remindersEnabled")
            } else {
                defaults.removeObject(forKey: "remindersEnabled")
            }
            SavedPlaceStore.save(previousPlace)
        }
        defaults.set(false, forKey: "remindersEnabled")
        ReminderScheduler.cancelAll()
        try await Task.sleep(nanoseconds: 300_000_000)
        let model = VoteViewModel()
        model.save(
            PollingLocation(
                name: "Beverly Hills Public Library", addr: "444 N Rexford Dr", type: "Civic Building",
                lat: nil, lng: nil, distance: nil, isEstimated: true
            ))
        try await Task.sleep(nanoseconds: 300_000_000)
        let afterSave = await pending()
        XCTAssertTrue(afterSave.isEmpty, "saving must not turn reminders back on")
        model.clearSavedPlace()
        try await Task.sleep(nanoseconds: 300_000_000)
        let afterRemoval = await pending()
        XCTAssertTrue(afterRemoval.isEmpty, "removing must not turn reminders back on")
    }

    @MainActor
    func testOptOutThenOptInWaitsForRealQueueCleanup() async throws {
        let suite = "ReminderQueueTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = ReminderPreferences(
            defaults: defaults, authorize: { true },
            schedule: {
                await ReminderScheduler.schedule(place: nil, calendar: self.calendar, now: self.futureStart)
            })
        await preferences.setEnabled(true).value
        let initiallyQueued = await pending()
        XCTAssertEqual(initiallyQueued.count, 2)
        await preferences.setEnabled(false).value
        let afterOptOut = await pending()
        XCTAssertTrue(afterOptOut.isEmpty)
        await preferences.setEnabled(true).value
        let afterOptIn = await pending()
        XCTAssertEqual(afterOptIn.count, 2)
        // Give any incorrectly delayed cancellation a chance to remove the new requests.
        try await Task.sleep(for: .milliseconds(300))
        let settled = await pending()
        XCTAssertEqual(settled.count, 2)
        await preferences.setEnabled(false).value
    }

    func testReschedulingReplacesRatherThanStacks() async throws {
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: futureStart)
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: futureStart)

        let requests = await pending()
        XCTAssertEqual(requests.count, 2, "rescheduling must replace, never stack")
    }

    func testCancelAllClearsEverything() async throws {
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: futureStart)
        ReminderScheduler.cancelAll()

        // removePendingNotificationRequests is asynchronous inside the daemon.
        try await Task.sleep(nanoseconds: 300_000_000)
        let remaining = await pending()
        XCTAssertTrue(remaining.isEmpty, "found \(remaining.map(\.identifier))")
    }

    func testAWeekBeforeInThePastIsNotScheduled() async throws {
        // Six days out: the week-before reminder has already passed and must be skipped, leaving
        // only the morning-of one. Scheduling a trigger in the past would never fire.
        let election = ElectionCalendar.next(from: futureStart, calendar: calendar)
        let sixDaysBefore = calendar.date(byAdding: .day, value: -6, to: election.date)!
        await ReminderScheduler.schedule(place: nil, calendar: calendar, now: sixDaysBefore)

        let requests = await pending()
        XCTAssertEqual(requests.count, 1)
        XCTAssertTrue(requests[0].identifier.contains("morning-of"))
    }
}
