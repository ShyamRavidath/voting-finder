import CoreLocation

/// One-shot "where am I" wrapper around CLLocationManager.
///
/// Accuracy is deliberately coarse: the coordinate is only ever used to look up a ZIP code, and
/// the server rounds to ~110 m anyway, so asking for a precise fix would cost battery and collect
/// more than the feature needs.
final class LocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    enum LocationError: LocalizedError {
        case denied
        case restricted
        case unavailable

        var errorDescription: String? {
            switch self {
            case .denied:
                "Location access is off. Turn it on in Settings, or enter your ZIP code instead."
            case .restricted:
                "Location access isn't available on this device. Enter your ZIP code instead."
            case .unavailable:
                "We couldn't get your location. Enter your ZIP code instead."
            }
        }
    }

    private let manager = CLLocationManager()
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isDenied: Bool {
        manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted
    }

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        var status = manager.authorizationStatus

        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                authContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways: break
        case .restricted: throw LocationError.restricted
        default: throw LocationError.denied
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Fires once on set-up too; only the user's actual answer should resume the request.
        guard manager.authorizationStatus != .notDetermined else { return }
        authContinuation?.resume(returning: manager.authorizationStatus)
        authContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            locationContinuation?.resume(throwing: LocationError.unavailable)
            locationContinuation = nil
            return
        }
        locationContinuation?.resume(returning: coordinate)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: LocationError.unavailable)
        locationContinuation = nil
    }
}
