import MapKit

@MainActor
enum MapDirections {
    static func open(name: String, address: String, latitude: Double?, longitude: Double?) {
        if let latitude, let longitude {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            item.name = name
            item.openInMaps(
                launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            )
            return
        }

        var components = URLComponents(string: "http://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "address", value: address)]
        if let url = components?.url {
            UIApplication.shared.open(url)
        }
    }
}
