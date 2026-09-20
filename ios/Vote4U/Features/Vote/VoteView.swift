import SwiftUI

struct VoteView: View {
    @State private var model = VoteViewModel()
    @FocusState private var zipFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchField

                    switch model.state {
                    case .idle:
                        officialLinks
                    case .loading:
                        ProgressView("Finding polling places…")
                            .padding(.vertical, 40)
                    case .loaded(let result):
                        results(result)
                    case .failed(let message):
                        ContentUnavailableView {
                            Label("Couldn't search", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(message)
                        } actions: {
                            Button("Try again") { Task { await model.search() } }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Find your polling place")
            .navigationBarTitleDisplayMode(.inline)
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
                    PollingLocationCard(location: location)
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
