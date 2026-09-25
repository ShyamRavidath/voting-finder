import UserNotifications

/// Local notifications only — no push server, no account, no cost, and nothing leaves the device.
/// Dates come from `ElectionCalendar`, the same rule the website uses, so reminders cannot go
/// stale as elections pass.
enum ReminderScheduler {
    private static let weekBeforeID = "election-week-before"
    private static let morningOfID = "election-morning-of"

    static func authorize() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [weekBeforeID, morningOfID]
        )
    }

    /// Re-scheduling is always a full replace, so changing the saved polling place updates the
    /// morning-of reminder text rather than stacking a second notification.
    @discardableResult
    static func schedule(
        place: SavedPlace? = SavedPlaceStore.load(),
        calendar: Calendar = .current,
        now: Date = Date()
    ) async -> Bool {
        let election = ElectionCalendar.next(from: now, calendar: calendar)
        let center = UNUserNotificationCenter.current()
        var scheduled: Set<String> = []

        // Deliberately NOT cancelAll() first. removePendingNotificationRequests is processed
        // asynchronously by the notification daemon, so a removal issued before these adds can
        // land after them and silently wipe the reminders we just scheduled — which is exactly
        // what happened, intermittently, until the tests caught it. Adding a request with an
        // existing identifier already replaces it atomically, so the replace is free; only the
        // reminders we decide *not* to schedule need an explicit removal, done at the end.

        // A week out, 9am: enough time to still register or plan early voting.
        if let weekBefore = calendar.date(byAdding: .day, value: -7, to: election.date),
            let fireDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: weekBefore),
            fireDate > now
        {
            let content = UNMutableNotificationContent()
            content.title = "\(election.kind) in one week"
            content.body = "Check your polling place and hours before Election Day."
            content.sound = .default

            if await add(id: weekBeforeID, content: content, at: fireDate, calendar: calendar, center: center) {
                scheduled.insert(weekBeforeID)
            }
        }

        // Election Day, 7am: name the saved place if there is one, because that is the detail
        // people actually need at that moment.
        if let fireDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: election.date), fireDate > now {
            let content = UNMutableNotificationContent()
            content.title = "Polls are open today"
            content.body =
                place.map { "Your saved polling place: \($0.name), \($0.addr)." }
                ?? "Today is Election Day. Find your polling place in Vote4U."
            content.sound = .default

            if await add(id: morningOfID, content: content, at: fireDate, calendar: calendar, center: center) {
                scheduled.insert(morningOfID)
            }
        }

        // Clear only what we did not just schedule — e.g. a week-before reminder whose date has
        // already passed, which must not linger from an earlier run.
        let stale = [weekBeforeID, morningOfID].filter { !scheduled.contains($0) }
        if !stale.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: stale)
        }

        return !scheduled.isEmpty
    }

    private static func add(
        id: String,
        content: UNMutableNotificationContent,
        at date: Date,
        calendar: Calendar,
        center: UNUserNotificationCenter
    ) async -> Bool {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}
