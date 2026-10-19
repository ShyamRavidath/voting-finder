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
    case home, vote, map
}

// Version 1 focuses on native voting tools; aggregated news is not part of this release.
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
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
        }
        .onChange(of: scenePhase, initial: true) {
            if scenePhase == .active {
                ReminderPreferences.shared.reconcile()
            }
        }
    }
}

extension Tab {
    /// Debug builds accept `-startTab vote` so screenshots and QA runs can land on a tab directly
    /// instead of needing UI automation to tap one. Compiled out of release builds entirely.
    static var initialFromLaunchArguments: Tab {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            guard let index = arguments.firstIndex(of: "-startTab"),
                let name = arguments[safe: index + 1]
            else { return .home }
            switch name {
            case "vote": return .vote
            case "map": return .map
            default: return .home
            }
        #else
            return .home
        #endif
    }
}

#if DEBUG
    extension Array {
        fileprivate subscript(safe index: Int) -> Element? {
            indices.contains(index) ? self[index] : nil
        }
    }
#endif
