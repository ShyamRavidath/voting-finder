import SwiftUI

@main
struct Vote4UApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

enum Tab: Hashable {
    case home, vote, map, news
}

// Four tabs mirroring the web app's information architecture. News is deliberately last:
// App Store guideline 4.2.2 treats a news aggregator as thin, so the voting tools lead.
struct RootView: View {
    @State private var selection: Tab = .initialFromLaunchArguments

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selection: $selection)
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)
            VoteView()
                .tabItem { Label("Vote", systemImage: "mappin.and.ellipse") }
                .tag(Tab.vote)
            ElectoralMapView()
                .tabItem { Label("Map", systemImage: "map") }
                .tag(Tab.map)
            NewsView()
                .tabItem { Label("News", systemImage: "newspaper") }
                .tag(Tab.news)
        }
    }
}

private extension Tab {
    /// Debug builds accept `-startTab vote` so screenshots and QA runs can land on a tab directly
    /// instead of needing UI automation to tap one. Compiled out of release builds entirely.
    static var initialFromLaunchArguments: Tab {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-startTab"),
              let name = arguments[safe: index + 1] else { return .home }
        switch name {
        case "vote": return .vote
        case "map": return .map
        case "news": return .news
        default: return .home
        }
        #else
        return .home
        #endif
    }
}

#if DEBUG
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
#endif
