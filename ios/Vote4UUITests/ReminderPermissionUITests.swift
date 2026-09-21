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

        // `matching(_:)`, NOT `containing(_:)`. `containing` keeps elements that have a
        // *descendant* satisfying the predicate and ignores the element's own attributes, so it
        // can never match a leaf button by its own label. It failed exactly that way on
        // 2026-09-21 — the diagnostic below printed `springboard buttons: ["Don't Allow",
        // "Allow"]` while claiming no button started with "Allow".
        let springboardButton = springboard.buttons.matching(matching).firstMatch
        if springboardButton.waitForExistence(timeout: timeout) {
            springboardButton.tap()
            return true
        }

        // Newer iOS does not always parent the permission alert to springboard.
        let app = XCUIApplication()
        let appButton = app.alerts.buttons.matching(matching).firstMatch
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
        let toggle = app.switches["election-reminder-toggle"]
        let scrollView = app.scrollViews.firstMatch

        // Home uses a LazyVStack, so the reminder card is not in the accessibility tree until
        // it is scrolled on screen. XCTest can report a partially clipped control as hittable,
        // so always advance the page once before testing or tapping it.
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10), "Home scroll view never appeared")
        scrollView.swipeUp()
        for _ in 0..<3 where !toggle.exists || !toggle.isHittable {
            scrollView.swipeUp()
        }

        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "reminder toggle never appeared")
        XCTAssertTrue(toggle.isHittable, "reminder toggle never became tappable")
        return toggle
    }

    private func tapSwitchControl(_ toggle: XCUIElement) {
        // SwiftUI exposes the full row as the switch's accessibility frame even though the
        // empty space between its label and control is not tappable on iOS 17.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    }

    func testAllowingNotificationsLeavesTheToggleOn() {
        let app = launch()
        let toggle = reminderToggle(in: app)
        XCTAssertEqual(toggle.value as? String, "0", "reminders start off")

        tapSwitchControl(toggle)
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

        tapSwitchControl(toggle)
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
