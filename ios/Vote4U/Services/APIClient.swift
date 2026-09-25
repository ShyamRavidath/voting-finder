import Foundation

enum APIError: LocalizedError {
    case offline
    case unreachable
    case timeout
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        // Only claim the user is offline when the system actually says so. A refused connection
        // or a DNS failure usually means our server is down, and telling someone with four bars
        // to check their connection sends them chasing the wrong problem.
        case .offline: "You appear to be offline. Check your connection and try again."
        case .unreachable: "We couldn't reach Vote4U. It may be temporarily down — please try again shortly."
        case .timeout: "That took too long. Please try again."
        case .server(let message): message
        case .decoding: "We got an unexpected response. Please try again."
        }
    }
}

private struct APIErrorBody: Decodable { let error: String }

/// Mirrors `client/src/lib/api.js`: hard timeouts and friendly, user-facing errors rather than
/// raw URLSession failures. The same Express API backs both the website and this app.
struct APIClient {
    static let shared = APIClient(baseURL: URL(string: "https://vote4ucyl.vercel.app")!)

    let baseURL: URL
    var timeout: TimeInterval = 15

    func polling(zip: String) async throws -> PollingResult {
        if let stubbed = try stubbedPolling() { return stubbed }
        return try await get("/api/polling", query: [URLQueryItem(name: "zip", value: zip)])
    }

    func polling(latitude: Double, longitude: Double) async throws -> PollingResult {
        if let stubbed = try stubbedPolling() { return stubbed }
        return try await get(
            "/api/polling",
            query: [
                URLQueryItem(name: "lat", value: String(latitude)),
                URLQueryItem(name: "lng", value: String(longitude)),
            ])
    }

    func news() async throws -> [Article] {
        if let stubbed = try stubbedNews() { return stubbed }
        let response: NewsResponse = try await get("/api/news", query: [])
        return response.articles
    }

    // Canned responses for UI tests, so the assertions about labelling and error states do not
    // depend on a third-party geocoder being in a good mood. `APIStub` does not exist in Release.
    private func stubbedPolling() throws -> PollingResult? {
        #if DEBUG
            switch APIStub.polling() {
            case .value(let result): return result
            case .failure(let error): throw error
            case nil: return nil
            }
        #else
            return nil
        #endif
    }

    private func stubbedNews() throws -> [Article]? {
        #if DEBUG
            switch APIStub.news() {
            case .value(let articles): return articles
            case .failure(let error): throw error
            case nil: return nil
            }
        #else
            return nil
        #endif
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = timeout

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost: throw APIError.offline
            case .timedOut: throw APIError.timeout
            default: throw APIError.unreachable
            }
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            // The API always sends a human-readable `error` string; prefer it over a status code.
            let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.error
            throw APIError.server(message ?? "Something went wrong. Please try again.")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
