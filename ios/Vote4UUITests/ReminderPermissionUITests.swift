import XCTest

/// The only way to answer a system permission alert in the Simulator is to tap it, which is what
/// XCUITest can do and `simctl privacy` cannot — it has no `notifications` service at all.
///
/// iOS asks once per install and remembers, so each direction needs a simulator where the alert
/// has not been answered yet. `scripts/test-ios.sh` creates a throwaway one for each.
///
/// Still out of reach here: seeing a banner actually arrive at its scheduled time. That needs a
/// real device.
final class ReminderPermissionUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-startTab", "home"]
        app.launch()
        // A newly created simulator is cold; tapping before the app is genuinely interactive
        // silently does nothing and the permission alert never appears.
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))
        return app
    }

    /// Matches on a prefix, never an exact string: iOS writes "Don’t Allow" with a typographic
    /// apostrophe (U+2019), which never equals a source-code "Don't Allow". That mismatch made
    /// this test silently skip for several runs while the flow underneath was broken.
    @discardableResult
    private func answerSystemAlert(prefix: String, timeout: TimeInterval = 30) -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let matching = NSPredicate(format: "label BEGINSWITH[c] %@", prefix)

        let springboardButton = springboard.buttons.containing(matching).firstMatch
        if springboardButton.waitForExistence(timeout: timeout) {
            springboardButton.tap()
            return true
        }

        // Newer iOS does not always parent the permission alert to springboard.
        let app = XCUIApplication()
        let appButton = app.alerts.buttons.containing(matching).firstMatch
        if appButton.waitForExistence(timeout: 5) {
            appButton.tap()
            return true
        }

        let diagnosis = [
            "No alert button starting with '\(prefix)'.",
            "springboard buttons: \(springboard.buttons.allElementsBoundByIndex.map(\.label))",
            "springboard alerts:  \(springboard.alerts.allElementsBoundByIndex.map(\.label))",
            "app alerts:          \(app.alerts.allElementsBoundByIndex.map(\.label))",
            "app buttons:         \(app.buttons.allElementsBoundByIndex.map(\.label))",
        ].joined(separator: "\n")
        XCTFail(diagnosis)
        return false
    }

    private func reminderToggle(in app: XCUIApplication) -> XCUIElement {
        let toggle = app.switches["Remind me about Election Day"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 20), "reminder toggle never appeared")
        return toggle
    }

    func testAllowingNotificationsLeavesTheToggleOn() {
        let app = launch()
        let toggle = reminderToggle(in: app)
        XCTAssertEqual(toggle.value as? String, "0", "reminders start off")

        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1", "the toggle tap did not register")

        answerSystemAlert(prefix: "Allow")

        // The app deliberately flips the toggle back when authorization fails, so it staying on
        // is a real assertion that scheduling was authorised — not just that a switch moved.
        XCTAssertEqual(toggle.value as? String, "1", "toggle should remain on after allowing")
        XCTAssertFalse(
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Notifications are turned off'")).firstMatch.exists,
            "no denial warning should be shown after allowing"
        )
    }

    func testDenyingNotificationsFlipsTheToggleBackAndExplains() {
        let app = launch()
        let toggle = reminderToggle(in: app)

        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1", "the toggle tap did not register")

        answerSystemAlert(prefix: "Don")

        // Regression guard: flipping the toggle back used to re-enter the change handler and wipe
        // this warning before it could be read, leaving denial completely unexplained.
        let warning = app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS 'Notifications are turned off'"))
            .firstMatch
        XCTAssertTrue(warning.waitForExistence(timeout: 10), "denial must be explained, not silent")
        XCTAssertEqual(toggle.value as? String, "0", "toggle must not sit on while scheduling nothing")
    }
}
