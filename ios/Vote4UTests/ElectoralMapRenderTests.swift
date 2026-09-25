import SwiftUI
import XCTest
@testable import Vote4U

/// Proof that the electoral map *draws the United States*, not merely that its path data parses.
///
/// `SVGPathTests` already checks that every bundled state produces a non-empty `Path`. That is a
/// weaker claim than it sounds: a regression in the parser or in `scripts/export-ios-data.mjs`
/// could transpose x and y, drop the scale, or collapse every ring into one corner, and every
/// existing assertion would still pass while the app rendered a wrong-but-not-crashing map that
/// only a human looking at the screen would notice.
///
/// The widget work established the technique this borrows: render with `ImageRenderer` and check
/// the bitmap, so no simulator UI automation is involved.
@MainActor
final class ElectoralMapRenderTests: XCTestCase {
    private let paths = BundledData.statePaths
    private lazy var statesByName = Dictionary(
        uniqueKeysWithValues: BundledData.states.map { ($0.name, $0) }
    )

    /// The canvas at the width an iPhone actually gives it.
    private func renderMap(width: CGFloat = 390) -> UIImage? {
        let height = width * paths.viewBox.height / paths.viewBox.width
        let view = ElectoralMapCanvas(
            paths: paths,
            statesByName: statesByName,
            selected: nil,
            onSelect: { _ in }
        )
        .frame(width: width, height: height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.uiImage
    }

    func testTheMapRendersSomethingVisible() throws {
        let image = try XCTUnwrap(renderMap(), "the canvas produced no image")
        XCTAssertEqual(image.size.width, 390, accuracy: 1)
        XCTAssertTrue(hasVisibleContent(image), "the map rendered blank")
    }

    /// A state drawn far outside the viewBox is a state the user cannot see. This is the
    /// assertion that a dropped or doubled scale factor trips.
    ///
    /// The margin is not laziness: us-atlas places the **Alaska inset** partly past the left
    /// edge of the projected canvas (its box starts at x ≈ -58 of a 975-wide viewBox), so strict
    /// containment fails on correct data. The web app renders the same file and clips it the
    /// same way. What is asserted instead is that every state overlaps the canvas and stays
    /// within one tenth of it — enough slack for that inset, nowhere near enough for a scale bug.
    func testEveryStateLandsOnTheCanvas() {
        let box = CGRect(x: 0, y: 0, width: paths.viewBox.width, height: paths.viewBox.height)
        let tolerant = box.insetBy(dx: -box.width * 0.1, dy: -box.height * 0.1)

        for shape in paths.shapes {
            let bounds = SVGPath.parse(shape.d).boundingRect
            XCTAssertFalse(bounds.isNull || bounds.isInfinite, "\(shape.name) has no usable bounds")
            XCTAssertTrue(
                tolerant.contains(bounds),
                "\(shape.name) is drawn off the canvas: \(bounds) vs \(box)"
            )
            XCTAssertTrue(bounds.intersects(box), "\(shape.name) does not overlap the canvas at all")
            XCTAssertGreaterThan(bounds.width, 0, "\(shape.name) has zero width")
            XCTAssertGreaterThan(bounds.height, 0, "\(shape.name) has zero height")
        }
    }

    /// …and the opposite failure: everything technically inside the box, but crushed into a
    /// corner. The 50 states plus DC should span most of the canvas they were projected onto.
    func testTheStatesTogetherFillTheCanvas() {
        let union = paths.shapes
            .map { SVGPath.parse($0.d).boundingRect }
            .reduce(CGRect.null) { $0.union($1) }

        XCTAssertGreaterThan(union.width, paths.viewBox.width * 0.9, "the map is squashed horizontally")
        XCTAssertGreaterThan(union.height, paths.viewBox.height * 0.7, "the map is squashed vertically")
    }

    /// Relative geography, which is what a transposed or flipped axis actually breaks. In the
    /// us-atlas Albers projection the canvas is screen-oriented: x grows east, y grows *south*.
    func testKnownStatesSitWhereTheyBelong() throws {
        let california = try center(of: "California")
        let florida = try center(of: "Florida")
        let maine = try center(of: "Maine")
        let texas = try center(of: "Texas")

        XCTAssertLessThan(california.x, texas.x, "California should be west of Texas")
        XCTAssertLessThan(texas.x, florida.x, "Texas should be west of Florida")
        XCTAssertLessThan(texas.x, maine.x, "Maine should be east of Texas")

        // y grows southward, so "north of" is "smaller y". A flipped vertical axis passes every
        // bounding-box check above and fails here.
        XCTAssertLessThan(maine.y, florida.y, "Maine should be north of Florida")
        XCTAssertLessThan(maine.y, texas.y, "Maine should be north of Texas")
    }

    /// Each state is painted its own party colour, checked on the rendered bitmap rather than by
    /// reading the model back. This is the assertion that catches geometry and colour drifting
    /// apart from each other — a state drawn in its neighbour's place still fails it.
    func testTheLargestStatesArePaintedTheirPartyColour() throws {
        let width: CGFloat = 780
        let scale = width / paths.viewBox.width
        let image = try XCTUnwrap(renderMap(width: width))
        let pixels = try XCTUnwrap(bitmap(of: image))

        // Big, convex-enough states, one from each end of the map.
        for name in ["California", "Texas", "Montana", "Florida"] {
            let state = try XCTUnwrap(statesByName[name], "\(name) missing from states.json")
            let path = SVGPath.parse(try shapeData(for: name), scale: CGSize(width: scale, height: scale))
            let point = try XCTUnwrap(interiorPoint(of: path), "found no interior point for \(name)")

            let sampled = try XCTUnwrap(pixels.color(atPointInPoints: point, imageScale: 2), "\(name) sample off-image")
            let expected = components(of: state.party.color)

            XCTAssertEqual(sampled.r, expected.r, accuracy: 0.12, "\(name) red channel")
            XCTAssertEqual(sampled.g, expected.g, accuracy: 0.12, "\(name) green channel")
            XCTAssertEqual(sampled.b, expected.b, accuracy: 0.12, "\(name) blue channel")
        }
    }

    // MARK: - helpers

    private func shapeData(for name: String) throws -> String {
        try XCTUnwrap(paths.shapes.first { $0.name == name }?.d, "\(name) missing from statePaths.json")
    }

    private func center(of name: String) throws -> CGPoint {
        let bounds = SVGPath.parse(try shapeData(for: name)).boundingRect
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    /// The centroid of a bounding box is not reliably inside a concave shape, so scan for a point
    /// the path actually contains.
    private func interiorPoint(of path: Path) -> CGPoint? {
        let bounds = path.boundingRect
        for fx in stride(from: 0.3, through: 0.7, by: 0.1) {
            for fy in stride(from: 0.3, through: 0.7, by: 0.1) {
                let point = CGPoint(x: bounds.minX + bounds.width * fx, y: bounds.minY + bounds.height * fy)
                if path.contains(point) { return point }
            }
        }
        return nil
    }

    private func components(of color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    private struct Bitmap {
        let pixels: [UInt8]
        let width: Int
        let height: Int

        /// `point` is in SwiftUI points; the bitmap is in pixels.
        func color(atPointInPoints point: CGPoint, imageScale: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
            let x = Int(point.x * imageScale)
            let y = Int(point.y * imageScale)
            guard x >= 0, y >= 0, x < width, y < height else { return nil }
            let offset = (y * width + x) * 4
            return (
                CGFloat(pixels[offset]) / 255,
                CGFloat(pixels[offset + 1]) / 255,
                CGFloat(pixels[offset + 2]) / 255
            )
        }
    }

    private func bitmap(of image: UIImage) -> Bitmap? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Bitmap(pixels: pixels, width: width, height: height)
    }

    private func hasVisibleContent(_ image: UIImage) -> Bool {
        guard let map = bitmap(of: image) else { return false }
        let first = Array(map.pixels.prefix(4))
        return stride(from: 0, to: map.pixels.count, by: 4).contains { offset in
            Array(map.pixels[offset..<min(offset + 4, map.pixels.count)]) != first
        }
    }
}
