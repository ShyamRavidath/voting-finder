import Foundation

struct PollingLocation: Codable, Identifiable, Equatable {
    let name: String
    let addr: String
    let type: String
    let lat: Double?
    let lng: Double?
    let distance: Double?
    let isEstimated: Bool?

    var id: String { "\(name)|\(addr)" }

    /// The API labels anything that did not come from an official source. Never present an
    /// estimated venue as confirmed — that is the rule the whole codebase is built around.
    var isConfirmed: Bool { isEstimated != true }

    var milesAway: String? {
        guard let distance else { return nil }
        let miles = distance * 0.621371
        return miles < 10 ? String(format: "%.1f mi", miles) : "\(Int(miles.rounded())) mi"
    }
}

struct PollingPlace: Codable, Equatable {
    let city: String
    let state: String
    let stateAbbr: String
    let zip: String?
}

struct PollingResult: Codable, Equatable {
    let locations: [PollingLocation]
    let place: PollingPlace?
    let dataSource: String
    let zip: String?

    var isOfficial: Bool { dataSource == "official" }
    var isEmpty: Bool { locations.isEmpty }
}

/// Field names match `server/services/newsService.js` exactly. `party` is non-nil only when the
/// headline names someone on the candidate watchlist; the Google News RSS fallback leaves it,
/// `excerpt` and `imageUrl` empty, so every one of them has to be optional.
struct Article: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let url: String
    let source: String?
    let date: String?
    let excerpt: String?
    let category: String?
    let candidate: String?
    let party: String?
    let imageUrl: String?
}

struct NewsResponse: Codable {
    let articles: [Article]
}
