import CoreLocation
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
    private(set) var savedPlace: SavedPlace? = SavedPlaceStore.load()
    var usingLocation = false

    var zip: String = "" {
        didSet {
            // Keep the field to 5 digits so the button state and the API contract agree.
            let digits = String(zip.filter(\.isNumber).prefix(5))
            if digits != zip { zip = digits }
        }
    }

    var canSearch: Bool { zip.count == 5 && state != .loading }
    var isBusy: Bool { state == .loading }

    private let client: APIClient
    private let location: LocationManager

    init(client: APIClient = .shared, location: LocationManager = LocationManager()) {
        self.client = client
        self.location = location
    }

    func search() async {
        guard zip.count == 5 else { return }
        usingLocation = false
        await run { try await self.client.polling(zip: self.zip) }
    }

    /// ZIP entry always remains available: guideline 5.1.1(iv) requires the app to work when
    /// location permission is declined, and plenty of people simply prefer typing it.
    func searchUsingLocation() async {
        usingLocation = true
        state = .loading
        do {
            let coordinate = try await location.currentCoordinate()
            let result = try await client.polling(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            // Reflect the resolved ZIP back into the field so the user can see, edit and re-run it.
            if let resolved = result.zip { zip = resolved }
            state = .loaded(result)
        } catch {
            state = .failed(message(for: error))
        }
    }

    func save(_ location: PollingLocation) {
        let place = SavedPlace(location: location)
        savedPlace = place
        SavedPlaceStore.save(place)
        // Keep the Election Day reminder naming the right place.
        Task { await ReminderScheduler.schedule(place: place) }
    }

    func clearSavedPlace() {
        savedPlace = nil
        SavedPlaceStore.save(nil)
        Task { await ReminderScheduler.schedule(place: nil) }
    }

    func isSaved(_ location: PollingLocation) -> Bool {
        savedPlace?.name == location.name && savedPlace?.addr == location.addr
    }

    private func run(_ work: @escaping () async throws -> PollingResult) async {
        state = .loading
        do {
            state = .loaded(try await work())
        } catch {
            state = .failed(message(for: error))
        }
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}
