import XCTest

@testable import Vote4U

@MainActor
final class ReminderPreferencesTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        suite = "ReminderPreferencesTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testForegroundRefreshesEnabledRemindersWithoutPrompting() async {
        defaults.set(true, forKey: "remindersEnabled")
        var scheduled = 0
        let preferences = ReminderPreferences(
            defaults: defaults,
            authorize: {
                XCTFail("Foreground must not prompt")
                return false
            },
            isAuthorized: { true }, schedule: { scheduled += 1 }, cancel: {})
        await preferences.reconcile().value
        await preferences.reconcile().value
        XCTAssertEqual(scheduled, 2)
        XCTAssertTrue(preferences.enabled)
    }

    func testRevocationClearsPendingRequestsAndPersistsWarning() async {
        defaults.set(true, forKey: "remindersEnabled")
        var cancelled = false
        let preferences = ReminderPreferences(
            defaults: defaults, isAuthorized: { false },
            schedule: { XCTFail("Revoked permission must not schedule") }, cancel: { cancelled = true })
        await preferences.reconcile().value
        XCTAssertTrue(cancelled)
        XCTAssertFalse(preferences.enabled)
        XCTAssertTrue(preferences.permissionDenied)
        XCTAssertTrue(ReminderPreferences(defaults: defaults).permissionDenied)
    }

    func testRestoringSystemPermissionClearsWarningWithoutOptingIn() async {
        defaults.set(true, forKey: "remindersPermissionDenied")
        let preferences = ReminderPreferences(
            defaults: defaults, isAuthorized: { true },
            schedule: { XCTFail("System permission is not an in-app opt-in") }, cancel: {})
        await preferences.reconcile().value
        XCTAssertFalse(preferences.permissionDenied)
        XCTAssertFalse(preferences.enabled)
    }

    func testOptOutWhileAuthorizationSuspendedCannotScheduleOrRestoreWarning() async {
        var authorization: CheckedContinuation<Bool, Never>?
        var started: CheckedContinuation<Void, Never>?
        var cancelled = false
        let preferences = ReminderPreferences(
            defaults: defaults,
            authorize: {
                await withCheckedContinuation {
                    authorization = $0
                    started?.resume()
                }
            }, schedule: { XCTFail("Stale opt-in scheduled") }, cancel: { cancelled = true })
        let enabling = preferences.setEnabled(true)
        await withCheckedContinuation { started = $0 }
        let disabling = preferences.setEnabled(false)
        authorization?.resume(returning: false)
        await enabling.value
        await disabling.value
        XCTAssertTrue(cancelled)
        XCTAssertFalse(preferences.enabled)
        XCTAssertFalse(preferences.permissionDenied)
    }

    func testOptOutDuringAddCleansUpAfterAddCompletes() async {
        var addition: CheckedContinuation<Void, Never>?
        var started: CheckedContinuation<Void, Never>?
        var events: [String] = []
        let preferences = ReminderPreferences(
            defaults: defaults, authorize: { true },
            schedule: {
                await withCheckedContinuation {
                    addition = $0
                    started?.resume()
                }
                events.append("added")
            }, cancel: { events.append("removed") })
        let enabling = preferences.setEnabled(true)
        await withCheckedContinuation { started = $0 }
        let disabling = preferences.setEnabled(false)
        addition?.resume()
        await enabling.value
        await disabling.value
        XCTAssertEqual(events, ["added", "removed"])
        XCTAssertFalse(preferences.enabled)
    }

    func testNewOptInWinsOverOlderQueuedOptOut() async {
        var events: [String] = []
        let preferences = ReminderPreferences(
            defaults: defaults, authorize: { true },
            schedule: { events.append("added") }, cancel: { events.append("removed") })
        preferences.setEnabled(true)
        preferences.setEnabled(false)
        await preferences.setEnabled(true).value
        XCTAssertEqual(events, ["added"])
        XCTAssertTrue(preferences.enabled)
    }
}
