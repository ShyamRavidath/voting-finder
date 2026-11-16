import Foundation

struct CivicSource: Codable, Hashable {
    let title: String
    let url: URL
}

struct CivicTopic: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let keywords: String
    let body: String
    let authority: String
    let process: String
    let action: String
    let actionURL: URL
    let checkedAt: Date
    let reviewBy: Date
    let sources: [CivicSource]

    func matches(_ query: String) -> Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || "\(title) \(keywords) \(body)".localizedCaseInsensitiveContains(
                query.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct CivicOutcome: Codable, Hashable {
    let summary: String
    let recordedAt: Date
    let source: CivicSource
}

struct CivicDecision: Codable, Identifiable, Hashable {
    let id: String
    let topicID: String
    let title: String
    let body: String
    let proposal: String
    let change: String
    let meetingAt: Date
    let timeZone: String
    let meetingLabel: String
    let commentDeadline: Date?
    let deadlineLabel: String
    let participation: String
    let status: String
    let outcome: CivicOutcome?
    let checkedAt: Date
    let reviewBy: Date
    let sources: [CivicSource]

    func isCurrent(at now: Date) -> Bool {
        checkedAt <= now && now < reviewBy
    }

    func canSaveCalendar(at now: Date) -> Bool {
        isCurrent(at: now) && status == "scheduled" && now < meetingAt
    }

    func statusLabel(at now: Date) -> String {
        if !isCurrent(at: now) { return "Needs a source recheck" }
        if status == "cancelled" { return "Cancelled" }
        if status == "postponed" { return "Postponed — check official agenda" }
        if outcome != nil { return "Outcome recorded" }
        if now >= meetingAt { return "Meeting time passed — outcome not verified" }
        return "Scheduled — outcome not verified"
    }

    func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: timeZone)
        return "\(formatter.string(from: date)) (\(timeZone))"
    }
}

struct CivicCatalog: Codable {
    let schemaVersion: Int
    let publishedAt: Date
    let communityID: String
    let communityName: String
    let coverage: String
    let topics: [CivicTopic]
    let decisions: [CivicDecision]

    static func decode(_ data: Data) throws -> CivicCatalog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let catalog = try decoder.decode(Self.self, from: data)
        try catalog.validate()
        return catalog
    }

    static func bundled() throws -> CivicCatalog {
        guard let url = Bundle.main.url(forResource: "local-civic", withExtension: "json") else {
            throw APIError.decoding
        }
        return try decode(Data(contentsOf: url))
    }

    /// Fail closed: an incomplete review cannot silently become an actionable deadline.
    func validate() throws {
        func trusted(_ url: URL) -> Bool {
            url.scheme == "https" && ["www.portland.gov", "trimet.org", "go.trimet.org"].contains(url.host)
        }
        func sourcesValid(_ sources: [CivicSource]) -> Bool {
            !sources.isEmpty && sources.allSatisfy { !$0.title.isEmpty && trusted($0.url) }
        }
        let topicIDs = Set(topics.map(\.id))
        guard schemaVersion == 1, communityID == "portland-or", !communityName.isEmpty,
            topicIDs.count == topics.count, Set(decisions.map(\.id)).count == decisions.count,
            topics.allSatisfy({
                !$0.id.isEmpty && !$0.title.isEmpty && !$0.authority.isEmpty && !$0.process.isEmpty
                    && trusted($0.actionURL) && sourcesValid($0.sources)
                    && $0.checkedAt <= publishedAt && $0.reviewBy > $0.checkedAt
                    && $0.reviewBy.timeIntervalSince($0.checkedAt) <= 31 * 86_400
            }),
            decisions.allSatisfy({
                topicIDs.contains($0.topicID) && !$0.id.isEmpty && !$0.proposal.isEmpty && !$0.change.isEmpty
                    && TimeZone(identifier: $0.timeZone) != nil && sourcesValid($0.sources)
                    && ["scheduled", "cancelled", "postponed", "decided"].contains($0.status)
                    && ($0.status != "decided" || $0.outcome != nil)
                    && ($0.outcome == nil
                        || ($0.status == "decided"
                            && sourcesValid([$0.outcome!.source]) && !$0.outcome!.summary.isEmpty
                            && $0.outcome!.recordedAt <= $0.checkedAt))
                    && $0.checkedAt <= publishedAt && $0.reviewBy > $0.checkedAt
                    && $0.reviewBy.timeIntervalSince($0.checkedAt) <= 7 * 86_400
                    && ($0.commentDeadline == nil || $0.commentDeadline! <= $0.meetingAt)
            })
        else { throw APIError.decoding }
    }
}
