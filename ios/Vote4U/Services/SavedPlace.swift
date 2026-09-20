import Foundation

/// The polling place the user chose to keep. Stored on device so it is readable with no network
/// at all — the one thing a voter most needs on Election Day morning, possibly in a dead zone.
struct SavedPlace: Codable, Equatable {
    let name: String
    let addr: String
    let lat: Double?
    let lng: Double?
    let savedAt: Date

    init(location: PollingLocation, savedAt: Date = Date()) {
        self.name = location.name
        self.addr = location.addr
        self.lat = location.lat
        self.lng = location.lng
        self.savedAt = savedAt
    }
}

enum SavedPlaceStore {
    private static let key = "savedPollingPlace"

    static func load() -> SavedPlace? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SavedPlace.self, from: data)
    }

    static func save(_ place: SavedPlace?) {
        guard let place, let data = try? JSONEncoder().encode(place) else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}
