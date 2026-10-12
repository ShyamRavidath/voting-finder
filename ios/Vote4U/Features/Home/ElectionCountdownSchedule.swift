import SwiftUI

/// An unbounded sequence of local midnights, including DST and the initial display instant.
struct ElectionCountdownSchedule: TimelineSchedule {
    var calendar = Calendar.current

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> Entries {
        Entries(nextDate: startDate, calendar: calendar)
    }

    struct Entries: Sequence, IteratorProtocol {
        var nextDate: Date?
        let calendar: Calendar

        mutating func next() -> Date? {
            guard let date = nextDate else { return nil }
            nextDate = ElectionCalendar.countdownRefreshDates(from: date, count: 1, calendar: calendar).last
            return date
        }
    }
}
