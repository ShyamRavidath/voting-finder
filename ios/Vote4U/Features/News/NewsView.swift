import SwiftUI

struct NewsView: View {
    @State private var model = NewsViewModel()
    @State private var reading: URL?

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .loading:
                    ProgressView()
                case .loaded(let articles) where articles.isEmpty:
                    ContentUnavailableView("No headlines right now", systemImage: "newspaper")
                case .loaded(let articles):
                    List(articles) { article in
                        Button { reading = URL(string: article.url) } label: {
                            NewsRow(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
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
            .navigationTitle("Election News")
            .task { if case .loading = model.state { await model.load() } }
            .sheet(item: $reading) { SafariView(url: $0).ignoresSafeArea() }
        }
    }
}

private struct NewsRow: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.subheadline.weight(.medium))
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
        .padding(.vertical, 4)
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

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview { NewsView() }
