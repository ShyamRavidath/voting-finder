import SwiftUI

struct VoteView: View {
    @State private var model = VoteViewModel()
    @FocusState private var zipFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchField
                    locationButton
                    if let saved = model.savedPlace { savedCard(saved) }

                    switch model.state {
                    case .idle:
                        officialLinks
                    case .loading:
                        ProgressView("Finding polling places…")
                            .padding(.vertical, 40)
                    case .loaded(let result):
                        results(result)
                    case .failed(let message):
                        // The official links are bundled, so they still work when the API does
                        // not — which is exactly when someone needs them most.
                        VStack(spacing: 12) {
                            ContentUnavailableView {
                                Label("Couldn't search", systemImage: "exclamationmark.triangle")
                            } description: {
                                Text(message)
                            } actions: {
                                Button("Try again") {
                                    Task {
                                        if model.usingLocation {
                                            await model.searchUsingLocation()
                                        } else {
                                            await model.search()
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            officialLinks
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Find your polling place")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                #if DEBUG
                // `-startZip 90210` runs a search on launch, for screenshots and QA.
                let arguments = ProcessInfo.processInfo.arguments
                if let index = arguments.firstIndex(of: "-startZip"),
                   index + 1 < arguments.count,
                   case .idle = model.state {
                    model.zip = arguments[index + 1]
                    await model.search()
                }
                #endif
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            TextField("ZIP code", text: $model.zip)
                .keyboardType(.numberPad)
                .textContentType(.postalCode)
                .focused($zipFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))
                .accessibilityLabel("ZIP code")

            Button("Search") {
                zipFocused = false
                Task { await model.search() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canSearch)
        }
    }

    private var locationButton: some View {
        Button {
            zipFocused = false
            Task { await model.searchUsingLocation() }
        } label: {
            Label("Use my location", systemImage: "location.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(model.isBusy)
    }

    private func savedCard(_ saved: SavedPlace) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Your saved polling place", systemImage: "bookmark.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(saved.name).font(.headline)
            Text(saved.addr).font(.subheadline).foregroundStyle(.secondary)
            Button("Remove", role: .destructive) { model.clearSavedPlace() }
                .font(.caption)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.tint.opacity(0.1), in: .rect(cornerRadius: 12))
    }

    @ViewBuilder
    private func results(_ result: PollingResult) -> some View {
        if result.isEmpty {
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "No polling places found",
                    systemImage: "mappin.slash",
                    description: Text("We'd rather show you nothing than guess. Use an official lookup below.")
                )
                officialLinks
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if let place = result.place {
                    Text("\(place.city), \(place.stateAbbr)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !result.isOfficial {
                    Label(
                        "These are likely locations from OpenStreetMap, not confirmed polling places. Always check an official source before you go.",
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                PollingMapView(locations: result.locations)

                ForEach(result.locations) { location in
                    PollingLocationCard(
                        location: location,
                        isSaved: model.isSaved(location),
                        onSave: { model.save(location) }
                    )
                }

                officialLinks
            }
        }
    }

    private var officialLinks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Official sources")
                .font(.headline)
            ForEach(BundledData.officialLinks) { link in
                Link(destination: URL(string: link.href)!) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(link.label).font(.subheadline.weight(.medium))
                        Text(link.source).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

#Preview { VoteView() }
