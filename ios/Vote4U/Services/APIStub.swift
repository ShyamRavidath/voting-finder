#if DEBUG
import Foundation

/// DEBUG-only canned API responses, selected by launch argument.
///
/// UI tests used to drive the Vote and News tabs through the live production API, which made them
/// hostage to a third-party geocoder: on 2026-09-20 Nominatim stopped returning any venue for ZIP
/// 90210 and a correct build failed with "no results from the live API". Worse, the states that
/// matter most — an empty result set, a server error — could never be provoked on demand.
///
/// This whole file is compiled out of Release, so fabricated venues can never reach a voter.
/// That is guideline 1.1.6 and the first rule in this codebase; `scripts/test-ios.sh` asserts it
/// by grepping the Release binary.
///
///     -stubPolling estimated   two unofficial venues, both labelled "Not confirmed"
///     -stubPolling empty       a successful lookup that found nothing
///     -stubPolling error       a server-side failure
///     -stubNews sample         three fixed headlines
///     -stubNews error          a server-side failure
enum APIStub {
    enum Outcome<T> {
        case value(T)
        case failure(APIError)
    }

    static func polling() -> Outcome<PollingResult>? {
        switch argument(for: "-stubPolling") {
        case "estimated": .value(estimated)
        case "empty": .value(empty)
        case "error": .failure(.server("The stubbed server is unavailable."))
        default: nil
        }
    }

    static func news() -> Outcome<[Article]>? {
        switch argument(for: "-stubNews") {
        case "sample": .value(articles)
        case "error": .failure(.server("The stubbed server is unavailable."))
        default: nil
        }
    }

    private static func argument(for flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    private static let place = PollingPlace(
        city: "Beverly Hills",
        state: "California",
        stateAbbr: "CA",
        zip: "90210"
    )

    /// Deliberately `isEstimated: true`: the labelling rule is the thing under test.
    private static let estimated = PollingResult(
        locations: [
            PollingLocation(
                name: "Beverly Hills Public Library",
                addr: "444 North Rexford Drive, Beverly Hills, California, 90210",
                type: "Likely Polling Place",
                lat: 34.0725,
                lng: -118.4001,
                distance: 1.93,
                isEstimated: true
            ),
            PollingLocation(
                name: "Roxbury Community Center",
                addr: "471 South Roxbury Drive, Beverly Hills, California, 90212",
                type: "Likely Early Voting",
                lat: 34.0619,
                lng: -118.4004,
                distance: 3.2,
                isEstimated: true
            ),
        ],
        place: place,
        dataSource: "estimated",
        zip: "90210"
    )

    private static let empty = PollingResult(
        locations: [],
        place: place,
        dataSource: "none",
        zip: "90210"
    )

    private static let articles: [Article] = [
        Article(
            id: "stub-1",
            title: "Stubbed headline: county clerks publish early voting hours",
            url: "https://example.com/stub-1",
            source: "Stub Wire",
            date: "2026-09-20T09:00:00Z",
            excerpt: nil,
            category: nil,
            candidate: nil,
            party: nil,
            imageUrl: nil
        ),
        Article(
            id: "stub-2",
            title: "Stubbed headline: ballot drop boxes open statewide",
            url: "https://example.com/stub-2",
            source: "Stub Wire",
            date: "2026-09-19T17:30:00Z",
            excerpt: nil,
            category: nil,
            candidate: nil,
            party: nil,
            imageUrl: nil
        ),
        Article(
            id: "stub-3",
            title: "Stubbed headline: registration deadline approaches",
            url: "https://example.com/stub-3",
            source: "Stub Wire",
            date: "2026-09-18T12:00:00Z",
            excerpt: nil,
            category: nil,
            candidate: nil,
            party: nil,
            imageUrl: nil
        ),
    ]
}
#endif
