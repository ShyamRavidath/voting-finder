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

    func testAllFourTabsExistInOrder() {
        let app = launch(["-startTab", "home"])
        for tab in ["Home", "Vote", "Map", "News"] {
            XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 10), "missing \(tab) tab")
        }
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
        XCTAssertTrue(app.buttons["Save"].firstMatch.exists)
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
        XCTAssertTrue(district.waitForExistence(timeout: 5),
                      "DC must be reachable through search even though it is unhittable on the map")
    }

    func testNewsTabLoadsHeadlines() {
        let app = launch(["-startTab", "news", "-stubNews", "sample"])
        XCTAssertTrue(app.navigationBars["Election News"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 15), "the stubbed headlines never rendered")
    }

    /// The one test that still talks to production. It deliberately accepts any *terminal* state:
    /// upstream data comes and goes (ZIP 90210 had no venues at all on 2026-09-20), so asserting
    /// a particular venue makes a correct build fail. What must never happen is the app hanging
    /// on a spinner or failing to decode what the API actually sends.
    func testLiveAPIReachesATerminalStateOnVoteAndNews() {
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

        app.tabBars.buttons["News"].tap()
        let headline = app.cells.firstMatch
        let noHeadlines = app.staticTexts["No headlines right now"]
        let newsFailed = app.staticTexts["Couldn't load the news"]
        let newsDeadline = Date().addingTimeInterval(45)
        while Date() < newsDeadline && !(headline.exists || noHeadlines.exists || newsFailed.exists) {
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(
            headline.exists || noHeadlines.exists || newsFailed.exists,
            "the News tab never left its loading state against the live API"
        )
    }
}
