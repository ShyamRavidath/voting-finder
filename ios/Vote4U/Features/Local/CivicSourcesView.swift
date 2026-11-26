import SwiftUI

struct CivicSourcesView: View {
    let checkedAt: Date
    let reviewBy: Date
    let sources: [CivicSource]
    let now: Date

    var body: some View {
        Section {
            ForEach(sources, id: \.self) { source in
                Link(source.title, destination: source.url)
            }
        } header: {
            Text("Sources")
        } footer: {
            Text(
                "Summary checked \(checkedAt.formatted(date: .abbreviated, time: .omitted)). Vote4U is independent of government."
            )
        }
    }
}
