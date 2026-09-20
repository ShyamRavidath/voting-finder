import SafariServices
import SwiftUI

/// Articles open in an in-app Safari view rather than punting to the browser: the reader stays in
/// the app, and the publisher still gets the real page (guideline 4.2.2 — we never reproduce
/// article content ourselves).
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
