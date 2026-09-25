import SwiftUI

struct NonpartisanNotice: View {
    var body: some View {
        Label {
            Text(
                "Vote4U is independent and nonpartisan. It is not affiliated with any government agency, election office, campaign, or party."
            )
        } icon: {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(.secondary)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}
