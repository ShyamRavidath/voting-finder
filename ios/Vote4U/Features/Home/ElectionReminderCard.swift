import SwiftUI

struct ElectionReminderCard: View {
    @Binding var isEnabled: Bool
    let permissionDenied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .font(.headline)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Toggle("Remind me about Election Day", isOn: $isEnabled)
                    .font(.headline)
                    .accessibilityIdentifier("election-reminder-toggle")
            }

            if permissionDenied {
                Label(deniedMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.orange.opacity(0.14), in: .rect(cornerRadius: 8))
            } else {
                Text(reminderMessage)
                    .font(.subheadline)
                    .foregroundStyle(Vote4UTheme.supportingText)
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
        .sensoryFeedback(.selection, trigger: isEnabled)
    }

    private var deniedMessage: String {
        "Notifications are turned off for Vote4U. Turn them on in Settings to get reminders."
    }

    private var reminderMessage: String {
        "One reminder a week before Election Day and another that morning—scheduled only on this device."
    }
}
