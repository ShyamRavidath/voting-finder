import Foundation

struct CivicService: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let url: URL

    // Plain-language labels for the featured official services; the full directory text
    // remains searchable and each result opens its original city page.
    var displayTitle: String {
        switch id {
        case "/police/drug-complaint": "Report drug activity"
        case "/parks/report": "Report a park problem"
        case "/311/contact-311": "Ask 311 for help"
        default: title
        }
    }

    var displaySummary: String {
        switch id {
        case "/police/drug-complaint": "Send a drug complaint to the Portland Police Bureau."
        case "/parks/report":
            "Report maintenance problems or safety hazards in Portland parks, trails, gardens or community centers."
        case "/311/contact-311": "Find the right city or county service for your question."
        default: summary
        }
    }

    func searchScore(_ query: String) -> Int {
        let ignored: Set<String> = [
            "i", "im", "am", "having", "have", "an", "a", "the", "with", "issues", "issue", "problem", "problems",
            "help", "me", "my", "in", "portland", "about", "and", "to", "need", "how", "do",
        ]
        let normalized = query.lowercased().replacingOccurrences(of: "’", with: "").replacingOccurrences(
            of: "'", with: "")
        let words = normalized.split { !$0.isLetter && !$0.isNumber }.map(String.init).filter {
            !ignored.contains($0)
        }
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return 1 }
        let terms = words.map { word in word.count > 3 && word.hasSuffix("s") ? String(word.dropLast()) : word }
        let heading = title.lowercased()
        let body = summary.lowercased()
        return terms.reduce(0) { score, term in score + (heading.contains(term) ? 10 : body.contains(term) ? 1 : 0) }
    }
}

struct CivicMeeting: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let url: URL
    let startsAt: Date
    let endsAt: Date?
    let status: String
    let online: Bool

    func canSave(at now: Date, fetchedAt: Date, listed: Bool) -> Bool {
        listed && status == "scheduled" && startsAt > now && fetchedAt <= now
            && now.timeIntervalSince(fetchedAt) < 86_400
    }

    var dateLabel: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        formatter.dateFormat = "EEE, MMM d · h:mm a z"
        return formatter.string(from: startsAt)
    }

    var shortTitle: String {
        title.replacingOccurrences(of: " Committee Meeting", with: " Committee")
            .replacingOccurrences(of: "City Council Meeting", with: "City Council")
    }
}

struct CivicAction: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL
    let agendaURL: URL
    let meetingAt: Date
    let action: String
    let notes: String
    let videoURL: URL?

    var displayTitle: String {
        switch id {
        case "2026-401": "Stark & Washington street safety project"
        case "2026-346": "Nonprofit housing tax exemption"
        default: title
        }
    }
}

struct CivicFeedSection<Item: Codable>: Codable {
    let fetchedAt: Date
    var source: String
    let items: [Item]
}

struct CivicFeed: Codable {
    let schemaVersion: Int
    var services: CivicFeedSection<CivicService>
    var meetings: CivicFeedSection<CivicMeeting>
    var actions: CivicFeedSection<CivicAction>

    static func decode(_ data: Data, now: Date = .now) throws -> Self {
        guard data.count < 2_000_000 else { throw APIError.decoding }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let feed = try decoder.decode(Self.self, from: data)
        func official(_ url: URL) -> Bool {
            url.scheme == "https" && url.host == "www.portland.gov" && url.user == nil && url.password == nil
                && (url.port == nil || url.port == 443)
        }
        func sectionValid<T>(_ section: CivicFeedSection<T>) -> Bool {
            section.fetchedAt <= now && section.fetchedAt > .distantPast
                && ["live", "saved"].contains(section.source)
        }
        guard feed.schemaVersion == 1, sectionValid(feed.services), sectionValid(feed.meetings),
            sectionValid(feed.actions), feed.services.items.count <= 1500, feed.meetings.items.count <= 100,
            feed.actions.items.count <= 300,
            Set(feed.services.items.map(\.id)).count == feed.services.items.count,
            Set(feed.meetings.items.map(\.id)).count == feed.meetings.items.count,
            Set(feed.actions.items.map(\.id)).count == feed.actions.items.count,
            feed.services.items.allSatisfy({ !$0.id.isEmpty && !$0.title.isEmpty && official($0.url) }),
            feed.meetings.items.allSatisfy({
                !$0.id.isEmpty && !$0.title.isEmpty && official($0.url)
                    && ["scheduled", "cancelled", "postponed"].contains($0.status)
                    && ($0.endsAt == nil || $0.endsAt! >= $0.startsAt)
            }),
            feed.actions.items.allSatisfy({
                !$0.id.isEmpty && !$0.title.isEmpty && !$0.action.isEmpty && official($0.url) && official($0.agendaURL)
                    && ($0.videoURL == nil
                        || ($0.videoURL!.scheme == "https" && $0.videoURL!.host == "www.youtube.com"
                            && $0.videoURL!.path == "/watch" && $0.videoURL!.user == nil
                            && $0.videoURL!.password == nil))
            })
        else { throw APIError.decoding }
        return feed
    }

    static func bundled() throws -> Self {
        guard let url = Bundle.main.url(forResource: "local-feed", withExtension: "json") else {
            throw APIError.decoding
        }
        return try decode(Data(contentsOf: url))
    }

    var savedCopy: Self {
        var copy = self
        copy.services.source = "saved"
        copy.meetings.source = "saved"
        copy.actions.source = "saved"
        return copy
    }
}
