import Foundation
import Observation

@MainActor @Observable
final class CivicStore {
    private(set) var catalog: CivicCatalog?
    private(set) var followed: Set<String>
    private(set) var communitySelected: Bool
    private(set) var refreshing = false
    private(set) var message = "Bundled guide. Pull to refresh for reviewed updates."
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let fetch: () async throws -> Data

    init(
        defaults: UserDefaults = .standard,
        fetch: @escaping () async throws -> Data = { try await CivicStore.fetchCatalog() }
    ) {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-resetCivic") {
                for key in ["civic.followed", "civic.portlandSelected", "civic.catalog"] {
                    defaults.removeObject(forKey: key)
                }
            }
        #endif
        self.defaults = defaults
        self.fetch = fetch
        followed = Set(defaults.stringArray(forKey: "civic.followed") ?? [])
        communitySelected = defaults.bool(forKey: "civic.portlandSelected")
        catalog = try? CivicCatalog.bundled()
        if let data = defaults.data(forKey: "civic.catalog"), let cached = try? CivicCatalog.decode(data),
            cached.publishedAt <= Date(), cached.publishedAt >= (catalog?.publishedAt ?? .distantPast)
        {
            catalog = cached
            message = "Saved guide. Pull to refresh for reviewed updates."
        }
    }

    func selectCommunity() {
        communitySelected = true
        defaults.set(true, forKey: "civic.portlandSelected")
    }

    func changeCommunity() {
        communitySelected = false
        defaults.set(false, forKey: "civic.portlandSelected")
    }

    func toggleFollow(_ id: String) {
        guard catalog?.topics.contains(where: { $0.id == id }) == true else { return }
        if followed.contains(id) { followed.remove(id) } else { followed.insert(id) }
        defaults.set(followed.sorted(), forKey: "civic.followed")
    }

    func refresh() async {
        guard !refreshing, communitySelected else { return }
        refreshing = true
        defer { refreshing = false }
        do {
            let data = try await fetch()
            let updated = try CivicCatalog.decode(data)
            guard updated.publishedAt <= Date(), updated.publishedAt >= (catalog?.publishedAt ?? .distantPast) else {
                throw APIError.decoding
            }
            catalog = updated
            defaults.set(data, forKey: "civic.catalog")
            message = "Reviewed guide downloaded. Check each record’s source date."
        } catch {
            message =
                catalog == nil
                ? "The guide is unavailable. Try again or open the official Council agenda."
                : "Couldn’t refresh. Showing the saved guide; dates and decisions may have changed."
        }
    }

    nonisolated private static func fetchCatalog() async throws -> Data {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-civicOffline") { throw APIError.offline }
        #endif
        let url = APIClient.shared.baseURL.appendingPathComponent("api/local-civic")
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.timeoutInterval = 15
        // No search, followed topics, ZIP, or coordinates leave this device.
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count < 1_000_000 else {
            throw APIError.decoding
        }
        return data
    }
}
