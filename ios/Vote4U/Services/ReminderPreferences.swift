import Foundation
import Observation

/// Serializes notification changes across Home, saved places, and foreground transitions.
@MainActor
@Observable
final class ReminderPreferences {
    static let shared = ReminderPreferences()

    private(set) var enabled: Bool
    private(set) var permissionDenied: Bool
    private let defaults: UserDefaults
    private let authorize: () async -> Bool
    private let isAuthorized: () async -> Bool
    private let schedule: () async -> Void
    private let cancel: () async -> Void
    private var revision = 0
    private var pending: Task<Void, Never>?

    init(
        defaults: UserDefaults = .standard,
        authorize: @escaping () async -> Bool = { await ReminderScheduler.authorize() },
        isAuthorized: @escaping () async -> Bool = { await ReminderScheduler.isAuthorized() },
        schedule: @escaping () async -> Void = { await ReminderScheduler.schedule() },
        cancel: @escaping () async -> Void = {
            await ReminderScheduler.cancelPending()
        }
    ) {
        self.defaults = defaults
        self.authorize = authorize
        self.isAuthorized = isAuthorized
        self.schedule = schedule
        self.cancel = cancel
        enabled = defaults.bool(forKey: "remindersEnabled")
        permissionDenied = defaults.bool(forKey: "remindersPermissionDenied")
    }

    @discardableResult
    func setEnabled(_ value: Bool) -> Task<Void, Never> {
        revision += 1
        enabled = value
        permissionDenied = false
        persist()
        return enqueue(requestPermission: value)
    }

    /// Never prompts on launch/foreground. Refreshes dates and saved-place wording when enabled.
    @discardableResult
    func reconcile() -> Task<Void, Never> {
        enqueue(requestPermission: false)
    }

    private func enqueue(requestPermission: Bool) -> Task<Void, Never> {
        let version = revision
        let previous = pending
        let task = Task {
            await previous?.value
            guard version == revision else { return }
            guard enabled else {
                if permissionDenied {
                    let granted = await isAuthorized()
                    guard version == revision else { return }
                    if granted {
                        permissionDenied = false
                        persist()
                    }
                }
                await cancel()
                return
            }
            let granted = await (requestPermission ? authorize() : isAuthorized())
            guard version == revision else { return }
            guard granted else {
                enabled = false
                permissionDenied = true
                persist()
                await cancel()
                return
            }
            permissionDenied = false
            persist()
            // A newer opt-out waits for this add to finish, then removes its requests. No old
            // scheduling task can finish after that cleanup and restore a notification.
            await schedule()
        }
        pending = task
        return task
    }

    private func persist() {
        defaults.set(enabled, forKey: "remindersEnabled")
        defaults.set(permissionDenied, forKey: "remindersPermissionDenied")
    }
}
