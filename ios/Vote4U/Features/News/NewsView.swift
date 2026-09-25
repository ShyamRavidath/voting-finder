import SwiftUI

struct NewsView: View {
    @State private var model = NewsViewModel()
    @State private var reading: ReadingDestination?

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .loading:
                    NewsLoadingView()
                case .loaded(let articles) where articles.isEmpty:
                    ContentUnavailableView("No headlines right now", systemImage: "newspaper")
                case .loaded(let articles):
                    List(articles) { article in
                        Button {
                            reading = URL(string: article.url).map(ReadingDestination.init)
                        } label: {
                            NewsRow(article: article)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await model.load() }
                case .failed(let message):
                    ContentUnavailableView {
                        Label("Couldn't load the news", systemImage: "wifi.slash")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try again") { Task { await model.load() } }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .background {
                Vote4UTheme.pageBackground
                    .ignoresSafeArea()
            }
            .navigationTitle("Election News")
            .task { if case .loading = model.state { await model.load() } }
            .sheet(item: $reading) { SafariView(url: $0.url).ignoresSafeArea() }
        }
    }
}

private struct NewsRow: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                HStack(spacing: 6) {
                    if let party = article.party {
                        Text(party)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(party == "Democrat" ? .blue : .red)
                    }
                    if let source = article.source {
                        Text(source)
                    }
                    let ago = Formatting.timeAgo(article.date)
                    if !ago.isEmpty {
                        Text("·")
                        Text(ago)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    }
                    // A broken thumbnail collapses instead of showing a torn-image placeholder,
                    // matching the web app's behaviour.
                }
                .frame(width: 72, height: 72)
                .clipShape(.rect(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens the article")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var parts = [article.title]
        if let source = article.source { parts.append(source) }
        let ago = Formatting.timeAgo(article.date)
        if !ago.isEmpty { parts.append(ago) }
        return parts.joined(separator: ", ")
    }
}

private struct ReadingDestination: Identifiable {
    let url: URL
    var id: URL { url }
}

#Preview { NewsView() }
