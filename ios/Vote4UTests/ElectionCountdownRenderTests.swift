import SwiftUI
import WidgetKit
import XCTest

@testable import Vote4U

/// Proof that the widget actually *draws*, not merely that it compiles.
///
/// Both matter, and they are not the same thing: the first version of this widget built cleanly,
/// embedded its `.appex`, and could never have appeared on anyone's Home Screen, because the
/// generated Info.plist had no `NSExtension` key. Driving springboard to the widget gallery is
/// the other obvious check and it is far too fragile to keep (see HANDOFF §4), so the views are
/// rendered directly instead — which is why they live in the app target.
@MainActor
final class ElectionCountdownRenderTests: XCTestCase {
    private var calendar: Calendar { Calendar(identifier: .gregorian) }

    /// The real widget sizes on a modern iPhone, plus the Lock Screen accessories.
    private static let sizes: [(family: WidgetFamily, size: CGSize)] = [
        (.systemSmall, CGSize(width: 170, height: 170)),
        (.systemMedium, CGSize(width: 364, height: 170)),
        (.accessoryRectangular, CGSize(width: 160, height: 72)),
        (.accessoryCircular, CGSize(width: 76, height: 76)),
        (.accessoryInline, CGSize(width: 200, height: 26)),
    ]

    private func entry(_ year: Int, _ month: Int, _ day: Int) -> ElectionCountdownEntry {
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        return ElectionCountdownEntry(date: date, election: ElectionCalendar.next(from: date, calendar: calendar))
    }

    private func render(_ entry: ElectionCountdownEntry, family: WidgetFamily, size: CGSize) async -> UIImage? {
        // `ElectionCountdownContent`, not `ElectionCountdownWidgetView`: `\.widgetFamily` is a
        // read-only environment key, so the family has to be passed in explicitly.
        let view = ElectionCountdownContent(entry: entry, family: family)
            .frame(width: size.width, height: size.height)

        return await renderWhenReady(view)
    }

    private func renderWhenReady<Content: View>(_ content: Content) async -> UIImage? {
        var image: UIImage?
        // A cold simulator can time out the first image provider while compiling its graphics
        // pipeline. Allow a bounded warm-up; callers still fail if the final image is blank.
        for attempt in 0..<3 {
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            image = renderer.uiImage
            if let image, hasVisibleContent(image) { return image }
            if attempt < 2 { try? await Task.sleep(for: .milliseconds(250)) }
        }
        return image
    }

    func testEveryFamilyRendersSomethingVisible() async throws {
        let entry = entry(2026, 9, 21)  // 43 days out

        for (family, size) in Self.sizes {
            let rendered = await render(entry, family: family, size: size)
            let image = try XCTUnwrap(rendered, "\(family) produced no image")
            XCTAssertEqual(image.size.width, size.width, accuracy: 1, "\(family) width")
            XCTAssertEqual(image.size.height, size.height, accuracy: 1, "\(family) height")
            XCTAssertTrue(hasVisibleContent(image), "\(family) rendered a blank image")
        }
    }

    /// Election Day and the day before are the two the phrasing special-cases, and they are also
    /// the widest strings the tiny families have to fit.
    func testTheEdgeCaseDaysStillRender() async throws {
        for entry in [entry(2026, 11, 3), entry(2026, 11, 2)] {
            for (family, size) in Self.sizes {
                let rendered = await render(entry, family: family, size: size)
                let image = try XCTUnwrap(
                    rendered,
                    "\(family) produced no image for \(entry.election.countdownPhrase)"
                )
                XCTAssertTrue(
                    hasVisibleContent(image),
                    "\(family) rendered blank for \(entry.election.countdownPhrase)"
                )
            }
        }
    }

    func testAPresidentialYearRendersToo() async throws {
        let entry = entry(2028, 3, 1)
        XCTAssertEqual(entry.election.shortKind(calendar: calendar), "Presidential")

        let rendered = await render(entry, family: .systemSmall, size: CGSize(width: 170, height: 170))
        let image = try XCTUnwrap(rendered)
        XCTAssertTrue(hasVisibleContent(image))
    }

    func testRenderWaitDoesNotAcceptPermanentlyBlankContent() async throws {
        let rendered = await renderWhenReady(Color.clear.frame(width: 170, height: 170))
        let image = try XCTUnwrap(rendered)
        XCTAssertFalse(hasVisibleContent(image), "the wait must not manufacture visible content")
    }

    /// A rendered-but-empty view is the failure this is really looking for, and a size check
    /// alone would sail straight past it. Samples the bitmap for more than one distinct pixel.
    private func hasVisibleContent(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }

        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        guard
            let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return false }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let first = Array(pixels.prefix(4))
        return stride(from: 0, to: pixels.count, by: 4).contains { offset in
            Array(pixels[offset..<min(offset + 4, pixels.count)]) != first
        }
    }
}
