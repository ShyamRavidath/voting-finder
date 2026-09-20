import Foundation
import Observation

@Observable
@MainActor
final class NewsViewModel {
    enum State: Equatable {
        case loading
        case loaded([Article])
        case failed(String)
    }

    private(set) var state: State = .loading

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await client.news())
        } catch {
            state = .failed((error as? APIError)?.errorDescription ?? "Couldn't load the news right now.")
        }
    }
}
