import XCTest

@testable import Vote4U

/// The electoral map is 109 KB of generated path data rendered through this parser, so a silent
/// failure here means a blank or mangled map rather than a crash.
final class SVGPathTests: XCTestCase {
    func testParsesASimpleClosedTriangle() {
        let path = SVGPath.parse("M0,0L10,0L10,10Z")
        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(path.boundingRect.width, 10, accuracy: 0.01)
        XCTAssertEqual(path.boundingRect.height, 10, accuracy: 0.01)
    }

    func testTreatsARunOfCoordinatesAfterOneLAsAPolyline() {
        // This is how the exporter writes every ring: a single L followed by many points.
        let path = SVGPath.parse("M0,0L5,5L10,0L20,40Z")
        XCTAssertEqual(path.boundingRect.maxY, 40, accuracy: 0.01)
        XCTAssertEqual(path.boundingRect.maxX, 20, accuracy: 0.01)
    }

    func testAppliesScale() {
        let path = SVGPath.parse("M0,0L10,0L10,10Z", scale: CGSize(width: 2, height: 3))
        XCTAssertEqual(path.boundingRect.width, 20, accuracy: 0.01)
        XCTAssertEqual(path.boundingRect.height, 30, accuracy: 0.01)
    }

    func testHandlesNegativeAndDecimalCoordinates() {
        let path = SVGPath.parse("M-5.5,-2.25L4.5,7.75Z")
        XCTAssertEqual(path.boundingRect.minX, -5.5, accuracy: 0.01)
        XCTAssertEqual(path.boundingRect.minY, -2.25, accuracy: 0.01)
    }

    func testHandlesMultipleSubpaths() {
        // Multi-polygon states (Hawaii, Alaska's islands) come through as several M...Z runs.
        let path = SVGPath.parse("M0,0L1,0L1,1ZM10,10L20,10L20,20Z")
        XCTAssertEqual(path.boundingRect.maxX, 20, accuracy: 0.01)
    }

    func testMalformedInputReturnsWithoutCrashing() {
        XCTAssertTrue(SVGPath.parse("").isEmpty)
        XCTAssertTrue(SVGPath.parse("Z").isEmpty)
        _ = SVGPath.parse("M0")  // truncated coordinate pair
        _ = SVGPath.parse("M0,0Lgarbage")
        _ = SVGPath.parse("Q5,5 10,10")  // command the exporter never emits
    }

    func testEveryBundledStateParsesToANonEmptyPath() {
        let shapes = BundledData.statePaths.shapes
        XCTAssertEqual(shapes.count, 51, "50 states plus DC")

        for shape in shapes {
            let path = SVGPath.parse(shape.d)
            XCTAssertFalse(path.isEmpty, "\(shape.name) produced an empty path")
            XCTAssertGreaterThan(path.boundingRect.width, 0, "\(shape.name) has no width")
        }
    }

    func testBundledDataMatchesTheElectoralCollege() {
        XCTAssertEqual(BundledData.totalElectoralVotes, 538)
        XCTAssertEqual(BundledData.states.count, 51)
    }
}
