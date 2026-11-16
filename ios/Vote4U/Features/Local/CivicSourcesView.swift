import SwiftUI

struct CivicSourcesView: View {
    let checkedAt: Date
    let reviewBy: Date
    let sources: [CivicSource]
    let now: Date

    var body: some View {
        Section("Sources and freshness") {
            Text("Source check: \(checkedAt.formatted(date: .abbreviated, time: .shortened))")
            Text("Recheck due: \(reviewBy.formatted(date: .abbreviated, time: .shortened))")
            if now >= reviewBy || now < checkedAt {
                Label(
                    "This record needs a source recheck. Confirm details with the agency.",
                    systemImage: "exclamationmark.triangle")
            }
            ForEach(sources, id: \.self) { source in
                Link(source.title, destination: source.url)
            }
            Text("Vote4U’s summary of official sources. Independent and nonpartisan; not a government service.")
                .font(.footnote)
                .foregroundStyle(Vote4UTheme.supportingText)
        }
    }
}
