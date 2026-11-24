import EventKit
import EventKitUI
import SwiftUI

/// iOS 17's system editor lets the person save or cancel without granting calendar access.
struct CivicCalendarEditor: UIViewControllerRepresentable {
    let title: String
    let start: Date
    let end: Date
    let sourceURL: URL?
    let notes: String

    init(decision: CivicDecision, onComplete: @escaping (Bool) -> Void) {
        title = decision.title
        start = decision.meetingAt
        end = decision.meetingAt
        sourceURL = decision.sources.first?.url
        notes =
            "Session start; individual item times may vary. Calendar copies do not update automatically.\n\n\(decision.proposal)"
        self.onComplete = onComplete
    }

    init(meeting: CivicMeeting, onComplete: @escaping (Bool) -> Void) {
        title = meeting.shortTitle
        start = meeting.startsAt
        end = meeting.endsAt ?? meeting.startsAt
        sourceURL = meeting.url
        notes =
            "Confirm the official meeting page before attending. Calendar copies do not update automatically.\n\n\(meeting.url.absoluteString)"
        self.onComplete = onComplete
    }
    let onComplete: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        let store = context.coordinator.store
        controller.eventStore = store
        controller.editViewDelegate = context.coordinator
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.timeZone = TimeZone(identifier: "America/Los_Angeles")
        event.url = sourceURL
        event.notes = notes
        controller.event = event
        return controller
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let store = EKEventStore()
        let onComplete: (Bool) -> Void

        init(onComplete: @escaping (Bool) -> Void) { self.onComplete = onComplete }

        func eventEditViewController(
            _ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction
        ) {
            onComplete(action == .saved)
        }
    }
}
