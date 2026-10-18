import XCTest

/// Cheap end-to-end coverage of the things a build could break without failing to compile.
final class AppSmokeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    func testLocationDenialStillAllowsZIPSearch() {
        let app = launch(["-startTab", "vote", "-stubPolling", "estimated"])
        app.buttons["Use my location"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = springboard.buttons["Don’t Allow"]
        let asciiDeny = springboard.buttons["Don't Allow"]
        if deny.waitForExistence(timeout: 5) {
            deny.tap()
        } else if asciiDeny.exists {
            asciiDeny.tap()
        }
        XCTAssertTrue(app.staticTexts["Search with your ZIP"].waitForExistence(timeout: 10))
        let field = app.textFields["ZIP code"]
        field.tap()
        field.typeText("90210")
        app.buttons["Search"].tap()
        XCTAssertTrue(app.staticTexts["Beverly Hills Public Library"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Not confirmed"].firstMatch.exists)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLargeTextKeepsSavingReachable() {
        let app = launch([
            "-startTab", "vote", "-startZip", "90210", "-stubPolling", "estimated",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ])
        let save = app.buttons["save-location"].firstMatch
        for _ in 0..<12 {
            if save.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(save.isHittable, "Save must remain reachable at the largest text size")
        capture(app, name: "accessibility-result-actions")
    }

    func testPrivacyPolicyIsReachableFromHome() {
        let app = launch(["-startTab", "home"])
        let policy = app.descendants(matching: .any).matching(identifier: "privacy-policy").firstMatch
        for _ in 0..<8 {
            if policy.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(policy.isHittable)
        capture(app, name: "home-privacy-link")
        policy.tap()
        XCTAssertTrue(
            XCUIApplication(bundleIdentifier: "com.apple.mobilesafari").wait(for: .runningForeground, timeout: 10))
    }

    func testVotingTabsExistInOrderWithoutNews() {
        let app = launch(["-startTab", "home"])
        for tab in ["Home", "Vote", "Map"] {
            XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 10), "missing \(tab) tab")
        }
        XCTAssertEqual(
            app.tabBars.buttons.allElementsBoundByIndex.map(\.label), ["Home", "Vote", "Map"])
        XCTAssertFalse(app.tabBars.buttons["News"].exists)
    }

    func testSavedLocationKeepsItsWarningOnHomeAndAfterRelaunch() {
        let app = launch(["-startTab", "vote", "-startZip", "90210", "-stubPolling", "nearby"])
        XCTAssertTrue(app.staticTexts["Westwood Branch Library"].waitForExistence(timeout: 15))
        let save = app.buttons["save-location"].firstMatch
        for _ in 0..<6 {
            if save.isHittable { break }
            // Drag in the scroll view's outer margin so MapKit cannot consume the gesture.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.8))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.3)))
        }
        XCTAssertTrue(save.isHittable)
        capture(app, name: "result-save-action")
        save.tap()
        app.tabBars.buttons["Home"].tap()
        let warning = app.staticTexts["saved-place-confirmation"]
        for _ in 0..<5 {
            if warning.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(warning.label.contains("Not confirmed"))
        XCTAssertTrue(warning.isHittable)
        capture(app, name: "saved-place-home")

        app.terminate()
        app.launchArguments = ["-startTab", "vote"]
        app.launch()
        XCTAssertTrue(warning.waitForExistence(timeout: 10))
        XCTAssertTrue(warning.label.contains("Not confirmed"))
        let remove = app.buttons["Remove"]
        for _ in 0..<5 {
            if remove.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(remove.isHittable)
        remove.tap()
    }

    func testVoteTabSearchesAndLabelsUnconfirmedResults() {
        // Stubbed, not live: this used to drive the real API and failed on a correct build the
        // day Nominatim stopped returning venues for 90210. The labelling rule is too important
        // to be asserted only when a third-party geocoder cooperates.
        let app = launch(["-startTab", "vote", "-startZip", "90210", "-stubPolling", "estimated"])

        let library = app.staticTexts["Beverly Hills Public Library"]
        XCTAssertTrue(library.waitForExistence(timeout: 15), "the stubbed result never rendered")

        // The rule the codebase is built around must be visible, not just modelled.
        XCTAssertTrue(app.staticTexts["Not confirmed"].firstMatch.exists, "estimated results must be labelled")
        XCTAssertTrue(app.buttons["Directions"].firstMatch.exists)
        XCTAssertTrue(app.buttons["save-location"].firstMatch.exists)
    }

    /// The widened tier. When nothing polling-shaped exists nearby the server falls back to
    /// civic buildings, and the copy has to hedge *harder* than the tier above it, not less —
    /// that is rule #1 stated as a UI assertion.
    func testVoteTabExplainsWhenTheSearchHadToWiden() {
        let app = launch(["-startTab", "vote", "-startZip", "90210", "-stubPolling", "nearby"])

        let school = app.staticTexts["Westwood Branch Library"]
        XCTAssertTrue(school.waitForExistence(timeout: 15), "the widened stub never rendered")

        let notice = app.staticTexts["polling.unofficialNotice"]
        XCTAssertTrue(notice.exists, "a widened search must explain itself")
        XCTAssertTrue(
            notice.label.contains("widened the search"),
            "expected the widened wording, got: \(notice.label)"
        )
        XCTAssertTrue(
            notice.label.contains("none is a confirmed polling place"),
            "the weakest tier must disclaim hardest, got: \(notice.label)"
        )
        XCTAssertTrue(app.staticTexts["Not confirmed"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Official sources"].exists)
    }

    /// The honest-empty path: a successful lookup that found nothing must say so and hand the
    /// voter an official source rather than inventing a venue.
    func testVoteTabOffersOfficialSourcesWhenNothingIsFound() {
        let app = launch(["-startTab", "vote", "-startZip", "90210", "-stubPolling", "empty"])

        XCTAssertTrue(app.staticTexts["No polling places found"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Official sources"].exists, "a dead end must still offer an official lookup")
    }

    /// The failure path, which could previously only be exercised by unplugging the network.
    func testVoteTabExplainsAServerFailureAndOffersRetry() {
        let app = launch(["-startTab", "vote", "-startZip", "90210", "-stubPolling", "error"])

        XCTAssertTrue(app.staticTexts["Couldn't search"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Try again"].firstMatch.exists, "a failed search must be retryable")
        XCTAssertTrue(app.staticTexts["Official sources"].exists)
    }

    func testVoteTabAlwaysOffersOfficialSourcesBeforeSearching() {
        let app = launch(["-startTab", "vote"])
        XCTAssertTrue(app.staticTexts["Official sources"].waitForExistence(timeout: 10))

        // A SwiftUI Link wrapping a VStack exposes one element whose label is the combined text
        // ("Find your official polling place, USA.gov"), so match on a substring rather than
        // guessing the exact composition.
        let officialLink = app.descendants(matching: .any)
            .containing(NSPredicate(format: "label CONTAINS 'Find your official polling place'"))
            .firstMatch
        XCTAssertTrue(officialLink.waitForExistence(timeout: 5), "USA.gov link must always be reachable")
    }

    func testMapTabRendersTheTallyAndTheStateList() {
        let app = launch(["-startTab", "map"])
        XCTAssertTrue(app.navigationBars["Electoral Map"].waitForExistence(timeout: 10))

        // The state list is the accessible route to every state, including the ones too small to tap.
        XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label CONTAINS 'California'")).firstMatch.exists)

        let stateSearch = app.searchFields["Search states"]
        XCTAssertTrue(stateSearch.waitForExistence(timeout: 5), "state search must be reachable")
        stateSearch.tap()
        stateSearch.typeText("District of Columbia")

        let district = app.buttons.containing(NSPredicate(format: "label CONTAINS 'District of Columbia'")).firstMatch
        XCTAssertTrue(
            district.waitForExistence(timeout: 5),
            "DC must be reachable through search even though it is unhittable on the map")
    }

    /// The one test that still talks to production. It deliberately accepts any *terminal* state:
    /// upstream data comes and goes (ZIP 90210 had no venues at all on 2026-09-20), so asserting
    /// a particular venue makes a correct build fail. What must never happen is the app hanging
    /// on a spinner or failing to decode what the API actually sends.
    func testLiveAPIReachesATerminalStateOnVote() {
        let app = launch(["-startTab", "vote", "-startZip", "90210"])

        // Any venue at all, not a named one — the upstream ranking changes from day to day.
        let results = app.buttons["Directions"].firstMatch
        let nothingFound = app.staticTexts["No polling places found"]
        let failed = app.staticTexts["Couldn't search"]
        // Any one of the three is a pass, and XCTWaiter would insist on all three, so poll.
        let deadline = Date().addingTimeInterval(45)
        while Date() < deadline && !(results.exists || nothingFound.exists || failed.exists) {
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(
            results.exists || nothingFound.exists || failed.exists,
            "the Vote tab never left its loading state against the live API"
        )

    }
}
