import Foundation

enum Formatting {
    static func date(fromISO string: String?) -> Date? {
        guard let string else { return nil }

        // FormatStyle is a Sendable value type, unlike a shared ISO8601DateFormatter. Foundation
        // caches identical styles internally, so creating these values is also inexpensive.
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string) {
            return date
        }
        return try? Date.ISO8601FormatStyle().parse(string)
    }

    /// Matches `timeAgo` in `client/src/lib/format.js` closely enough that a headline reads the
    /// same on both surfaces.
    static func timeAgo(_ string: String?, now: Date = Date()) -> String {
        guard let date = date(fromISO: string) else { return "" }
        let minutes = max(0, Int(now.timeIntervalSince(date) / 60))
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes) min ago" }

        let hours = minutes / 60
        if hours < 24 { return "\(hours) hr ago" }

        let days = hours / 24
        if days < 7 { return "\(days) day\(days == 1 ? "" : "s") ago" }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
