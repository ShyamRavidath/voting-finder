import EventKit
import EventKitUI
import SwiftUI

/// iOS 17's system editor lets the person save or cancel without granting calendar access.
struct CivicCalendarEditor: UIViewControllerRepresentable {
    let decision: CivicDecision
    let onComplete: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        let store = context.coordinator.store
        controller.eventStore = store
        controller.editViewDelegate = context.coordinator
        let event = EKEvent(eventStore: store)
        event.title = "Portland Council session: \(decision.title)"
        event.startDate = decision.meetingAt
        // A point-in-time reminder of the session start; the source does not fix the item end.
        event.endDate = decision.meetingAt
        event.timeZone = TimeZone(identifier: decision.timeZone)
        event.url = decision.sources.first?.url
        event.notes =
            "Session start, not a guaranteed item time. Check the official agenda before attending. Calendar copies do not update automatically.\n\n\(decision.proposal)\n\nhttps://www.portland.gov/council/agenda"
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
