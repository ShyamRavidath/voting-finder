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
        let center = UNUserNotificationCenter.current()
        var scheduled: Set<String> = []
        // Deliberately NOT cancelAll() first. removePendingNotificationRequests is processed
        // asynchronously by the notification daemon, so a removal issued before these adds can
        // land after them and silently wipe the reminders we just scheduled — which is exactly
        // what happened, intermittently, until the tests caught it. Adding a request with an
        // existing identifier already replaces it atomically, so the replace is free; only the
        // reminders we decide *not* to schedule need an explicit removal, done at the end.

        for request in requests(place: place, calendar: calendar, now: now) {
            do {
                try await center.add(request)
                scheduled.insert(request.identifier)
            } catch {
                // A failed replacement must not leave old saved-place wording queued.
            }
        }
        let stale = [weekBeforeID, morningOfID].filter { !scheduled.contains($0) }
        await removePending(identifiers: stale)
        return !scheduled.isEmpty
    }

    static func cancelPending() async {
        await removePending(identifiers: [weekBeforeID, morningOfID])
    }

    private static func removePending(identifiers: [String]) async {
        guard !identifiers.isEmpty else { return }
        let center = UNUserNotificationCenter.current()
        let existing = await center.pendingNotificationRequests()
        let removing = existing.map(\.identifier).filter { identifiers.contains($0) }
        // Do not enqueue a no-op removal that could race with a subsequent opt-in's add.
        guard !removing.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: removing)
        // Removal has no completion callback. Observe its effect before releasing our serial
        // queue, so a newer opt-in cannot add requests while this removal is still pending.
        while await center.pendingNotificationRequests().contains(where: { removing.contains($0.identifier) }) {
            try? await Task.sleep(for: .milliseconds(25))
        }
    }

    /// Pure request construction: fixed historical dates can be tested without the real clock.
    static func requests(place: SavedPlace?, calendar: Calendar, now: Date) -> [UNNotificationRequest] {
        let election = ElectionCalendar.next(from: now, calendar: calendar)
        var requests: [UNNotificationRequest] = []

        // A week out, 9am: enough time to still register or plan early voting.
        if let weekBefore = calendar.date(byAdding: .day, value: -7, to: election.date),
            let fireDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: weekBefore),
            fireDate > now
        {
            let content = UNMutableNotificationContent()
            content.title = "\(election.kind) in one week"
            content.body = "Check your polling place and hours before Election Day."
            content.sound = .default

            requests.append(request(id: weekBeforeID, content: content, at: fireDate, calendar: calendar))
        }

        // Election Day, 7am: name the saved place if there is one, because that is the detail
        // people actually need at that moment.
        if let fireDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: election.date), fireDate > now {
            let content = UNMutableNotificationContent()
            content.title = "Today is Election Day"
            content.body =
                place.map { "Saved location: \($0.name), \($0.addr). \($0.confirmationNotice)" }
                ?? "Today is Election Day. Find your polling place in Vote4U."
            content.sound = .default

            requests.append(request(id: morningOfID, content: content, at: fireDate, calendar: calendar))
        }

        return requests
    }

    private static func request(
        id: String,
        content: UNMutableNotificationContent,
        at date: Date,
        calendar: Calendar
    ) -> UNNotificationRequest {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }
}
