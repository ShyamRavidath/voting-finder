import SwiftUI

struct AppInformationLinks: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link("Privacy policy", destination: URL(string: "https://vote4ucyl.vercel.app/privacy")!)
                .accessibilityIdentifier("privacy-policy")
                .frame(minHeight: 44)
            Link("Support", destination: URL(string: "https://github.com/ShyamRavidath/voting-finder/issues")!)
                .frame(minHeight: 44)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
