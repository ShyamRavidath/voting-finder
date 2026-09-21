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
    /// How far the server had to look. Only present for the unofficial tiers; `searchRadiusKm`
    /// is optional so an older cached payload still decodes (HANDOFF §4: an all-Optional model
    /// happily decodes the wrong field names, so this one is pinned by a test).
    let searchRadiusKm: Double?

    /// The server answers in tiers, weakest last:
    /// `official` → Google's Voting Information Project.
    /// `estimated` → polling-type venues found in the immediate area.
    /// `nearby`  → nothing in the immediate area, so the search was widened to civic buildings.
    /// `none`    → we found nothing and say so, rather than inventing anything.
    var isOfficial: Bool { dataSource == "official" }
    var isWidened: Bool { dataSource == "nearby" }
    var isEmpty: Bool { locations.isEmpty }

    /// Miles, rounded, for the widened-search copy. Nil when the server didn't report a radius.
    var searchRadiusMiles: Int? {
        guard let searchRadiusKm else { return nil }
        return Int((searchRadiusKm * 0.621371).rounded())
    }
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
