import SwiftUI

/// Phase 2: ZIP entry, "use my location" (CoreLocation -> /api/polling?lat=&lng=), result cards,
/// a MapKit map, and the saved polling place. The backend for all of it already exists.
struct VoteView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Polling place finder", systemImage: "mappin.and.ellipse")
            } description: {
                Text("Coming in the next build.")
            } actions: {
                ForEach(BundledData.officialLinks) { link in
                    Link(link.label, destination: URL(string: link.href)!)
                }
            }
            .navigationTitle("Vote")
        }
    }
}

#Preview { VoteView() }
