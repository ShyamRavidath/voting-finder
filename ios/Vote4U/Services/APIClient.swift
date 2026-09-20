import Foundation

enum APIError: LocalizedError {
    case offline
    case timeout
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .offline: "You appear to be offline. Check your connection and try again."
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
        try await get("/api/polling", query: [URLQueryItem(name: "zip", value: zip)])
    }

    func polling(latitude: Double, longitude: Double) async throws -> PollingResult {
        try await get("/api/polling", query: [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
        ])
    }

    func news() async throws -> [Article] {
        let response: NewsResponse = try await get("/api/news", query: [])
        return response.articles
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
            default: throw APIError.offline
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
