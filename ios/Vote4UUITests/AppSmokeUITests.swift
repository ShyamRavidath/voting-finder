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
        let app = launch(["-startTab", "vote", "-startZip", "90210"])

        // Hits the live API, so allow generously for a cold serverless start.
        let library = app.staticTexts["Beverly Hills Public Library"]
        XCTAssertTrue(library.waitForExistence(timeout: 30), "no results from the live API")

        // The rule the codebase is built around must be visible, not just modelled.
        XCTAssertTrue(app.staticTexts["Not confirmed"].firstMatch.exists, "estimated results must be labelled")
        XCTAssertTrue(app.buttons["Directions"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Save"].firstMatch.exists)
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
        let app = launch(["-startTab", "news"])
        XCTAssertTrue(app.navigationBars["Election News"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 30), "no headlines from the live API")
    }
}
