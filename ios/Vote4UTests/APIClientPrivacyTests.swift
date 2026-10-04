import XCTest
@testable import Vote4U

final class APIClientPrivacyTests: XCTestCase {
    func testDeviceCoordinatesAreRoundedBeforeEnteringTheRequestURL() {
        let items = APIClient.locationQueryItems(latitude: 39.1582345, longitude: -75.5219876)

        XCTAssertEqual(items.first { $0.name == "lat" }?.value, "39.158")
        XCTAssertEqual(items.first { $0.name == "lng" }?.value, "-75.522")
    }
}
