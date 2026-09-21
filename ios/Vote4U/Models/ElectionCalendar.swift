import Foundation

struct FederalElection: Equatable {
    let date: Date
    let daysAway: Int
    let kind: String
}

extension FederalElection {
    /// Whether this is a presidential year. Derived from the date rather than by comparing
    /// `kind` against a string literal, so the two can never drift apart.
    func isPresidential(calendar: Calendar = .current) -> Bool {
        calendar.component(.year, from: date).isMultiple(of: 4)
    }

    /// "Today" / "Tomorrow" / "43 days".
    ///
    /// The widget has no room to spell out a sentence, and the two edge cases matter: "0 days"
    /// is wrong on the one day the app exists for, and "1 days" is just wrong.
    var countdownPhrase: String {
        switch daysAway {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "\(daysAway) days"
        }
    }

    /// The tight-space label. "Midterm elections" does not fit a small widget.
    func shortKind(calendar: Calendar = .current) -> String {
        isPresidential(calendar: calendar) ? "Presidential" : "Midterms"
    }

    /// Spoken by VoiceOver. Never reads a bare number, which on its own means nothing.
    func spokenSummary(calendar: Calendar = .current) -> String {
        let when: String
        switch daysAway {
        case 0: when = "is today"
        case 1: when = "is tomorrow"
        default: when = "is in \(daysAway) days"
        }
        return "\(kind) \(when), \(date.formatted(date: .complete, time: .omitted))"
    }
}

/// U.S. federal general elections: the Tuesday after the first Monday in November of even years.
/// Ported from `client/src/lib/format.js` so the app and the website can never disagree about the
/// date — it drives both the countdown and the notification schedule, so it must not go stale.
enum ElectionCalendar {
    static func next(from now: Date = Date(), calendar: Calendar = .current) -> FederalElection {
        let today = calendar.startOfDay(for: now)
        var year = calendar.component(.year, from: today)

        while true {
            defer { year += 1 }
            guard year.isMultiple(of: 2) else { continue }
            guard let date = electionDay(in: year, calendar: calendar), date >= today else { continue }

            let days = calendar.dateComponents([.day], from: today, to: date).day ?? 0
            return FederalElection(
                date: date,
                daysAway: days,
                kind: year.isMultiple(of: 4) ? "Presidential election" : "Midterm elections"
            )
        }
    }

    /// The instants a countdown needs to be recomputed: now, then each following local midnight.
    ///
    /// Lives here rather than in the widget because it is calendar arithmetic, and because the
    /// widget target cannot be imported by the test bundle — logic that hides in an app
    /// extension is logic that never gets a test.
    ///
    /// Midnights, not hours: the number changes once a day, and WidgetKit budgets refreshes per
    /// app per day. Asking to be woken hourly is how a widget gets throttled and goes stale.
    static func countdownRefreshDates(from now: Date, count: Int, calendar: Calendar = .current) -> [Date] {
        guard count > 0 else { return [now] }

        var dates = [now]
        var day = calendar.startOfDay(for: now)

        for _ in 0..<count {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
            dates.append(day)
        }
        return dates
    }

    private static func electionDay(in year: Int, calendar: Calendar) -> Date? {
        guard let nov1 = calendar.date(from: DateComponents(year: year, month: 11, day: 1)) else { return nil }
        // Calendar weekdays are 1-based from Sunday; JS getDay() is 0-based, hence the -1.
        let weekday = calendar.component(.weekday, from: nov1) - 1
        let firstMonday = 1 + ((8 - weekday) % 7)
        return calendar.date(from: DateComponents(year: year, month: 11, day: firstMonday + 1))
    }
}
