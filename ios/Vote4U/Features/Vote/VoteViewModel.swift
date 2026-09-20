import Foundation
import Observation

@Observable
@MainActor
final class VoteViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(PollingResult)
        case failed(String)
    }

    private(set) var state: State = .idle
    var zip: String = "" {
        didSet {
            // Keep the field to 5 digits so the button state and the API contract agree.
            let digits = String(zip.filter(\.isNumber).prefix(5))
            if digits != zip { zip = digits }
        }
    }

    var canSearch: Bool { zip.count == 5 && state != .loading }

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func search() async {
        guard zip.count == 5 else { return }
        state = .loading
        do {
            state = .loaded(try await client.polling(zip: zip))
        } catch {
            state = .failed((error as? APIError)?.errorDescription ?? "Something went wrong. Please try again.")
        }
    }
}
