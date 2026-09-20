import SwiftUI

/// Parses the tiny subset of SVG path syntax that `scripts/export-ios-data.mjs` emits: absolute
/// `M x,y`, `L x,y` and `Z`, repeated per polygon ring. The us-atlas "albers" source is already
/// projected onto a flat 975x610 canvas, so there is no map projection to do on the device — and
/// no tiles, no API key, and the map works offline.
enum SVGPath {
    static func parse(_ d: String, scale: CGSize = CGSize(width: 1, height: 1)) -> Path {
        var path = Path()
        var index = d.startIndex

        func skipSeparators() {
            while index < d.endIndex, d[index] == " " || d[index] == "," {
                index = d.index(after: index)
            }
        }

        func readNumber() -> CGFloat? {
            skipSeparators()
            let start = index
            while index < d.endIndex, d[index].isNumber || d[index] == "-" || d[index] == "." {
                index = d.index(after: index)
            }
            // Spelled out rather than `.map(CGFloat.init)`: that initialiser is overloaded
            // enough to blow up Swift's type inference here.
            guard start < index, let value = Double(String(d[start..<index])) else { return nil }
            return CGFloat(value)
        }

        func readPoint() -> CGPoint? {
            guard let x = readNumber(), let y = readNumber() else { return nil }
            return CGPoint(x: x * scale.width, y: y * scale.height)
        }

        while index < d.endIndex {
            let command = d[index]
            index = d.index(after: index)

            switch command {
            case "M":
                guard let point = readPoint() else { return path }
                path.move(to: point)
            case "L":
                guard let point = readPoint() else { return path }
                path.addLine(to: point)
                // A run of coordinates after one L is an implicit polyline, which is how the
                // exporter writes every ring.
                while let next = readPoint() { path.addLine(to: next) }
            case "Z", "z":
                path.closeSubpath()
            default:
                break // Unknown command: the exporter never emits one, so skip rather than fail.
            }
        }

        return path
    }
}
