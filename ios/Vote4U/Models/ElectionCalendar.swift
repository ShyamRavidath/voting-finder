import Foundation

struct FederalElection: Equatable {
    let date: Date
    let daysAway: Int
    let kind: String
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

    private static func electionDay(in year: Int, calendar: Calendar) -> Date? {
        guard let nov1 = calendar.date(from: DateComponents(year: year, month: 11, day: 1)) else { return nil }
        // Calendar weekdays are 1-based from Sunday; JS getDay() is 0-based, hence the -1.
        let weekday = calendar.component(.weekday, from: nov1) - 1
        let firstMonday = 1 + ((8 - weekday) % 7)
        return calendar.date(from: DateComponents(year: year, month: 11, day: firstMonday + 1))
    }
}
