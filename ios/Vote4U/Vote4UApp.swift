import SwiftUI

@main
struct Vote4UApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// Four tabs mirroring the web app's information architecture. News is deliberately last:
// App Store guideline 4.2.2 treats a news aggregator as thin, so the voting tools lead.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            VoteView()
                .tabItem { Label("Vote", systemImage: "mappin.and.ellipse") }
            ElectoralMapView()
                .tabItem { Label("Map", systemImage: "map") }
            NewsView()
                .tabItem { Label("News", systemImage: "newspaper") }
        }
    }
}
