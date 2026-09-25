import SwiftUI

struct VoteView: View {
    @State private var model = VoteViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Vote4UTheme.sectionSpacing) {
                    VoteSearchForm(
                        zip: $model.zip,
                        canSearch: model.canSearch,
                        isBusy: model.isBusy,
                        onSearch: search,
                        onUseLocation: searchUsingLocation
                    )

                    if let savedPlace = model.savedPlace {
                        SavedPollingPlaceCard(place: savedPlace, onRemove: model.clearSavedPlace)
                    }

                    VoteStateContent(
                        state: model.state,
                        savedPlace: model.savedPlace,
                        onRetry: retry,
                        onSave: model.save
                    )
                }
                .padding()
            }
            .background {
                Vote4UTheme.pageBackground
                    .ignoresSafeArea()
            }
            .navigationTitle("Find your polling place")
            .navigationBarTitleDisplayMode(.inline)
            .task { await searchFromLaunchArguments() }
        }
    }

    private func search() {
        Task { await model.search() }
    }

    private func searchUsingLocation() {
        Task { await model.searchUsingLocation() }
    }

    private func retry() {
        Task {
            if model.usingLocation {
                await model.searchUsingLocation()
            } else {
                await model.search()
            }
        }
    }

    private func searchFromLaunchArguments() async {
        #if DEBUG
            // `-startZip 90210` runs a search on launch, for screenshots and QA.
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "-startZip"),
                index + 1 < arguments.count,
                case .idle = model.state
            {
                model.zip = arguments[index + 1]
                await model.search()
            }
        #endif
    }
}

#Preview { VoteView() }
