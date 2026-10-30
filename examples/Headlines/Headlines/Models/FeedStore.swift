import Foundation
import Observation

/// Loads a feed a page at a time.
@Observable
final class FeedStore {
    enum Phase: Equatable {
        case idle, loading, loaded
        case failed(String)
    }

    static let pageSize = 30

    private(set) var feed: Feed = .top
    private(set) var stories: [Story] = []
    private(set) var phase: Phase = .idle
    private(set) var isLoadingMore = false
    @ObservationIgnored private var ids: [Int] = []
    @ObservationIgnored private var nextIndex = 0
    let client: HNClient

    init(client: HNClient) {
        self.client = client
    }

    var hasMore: Bool { nextIndex < ids.count }

    /// Loads the first page of `feed`, replacing what's shown.
    func load(_ feed: Feed) async {
        self.feed = feed
        if stories.isEmpty { phase = .loading }
        do {
            let ids = try await client.storyIDs(feed)
            let page = try await client.stories(ids: Array(ids.prefix(Self.pageSize)))
            guard feed == self.feed else { return }  // the user switched feeds meanwhile
            self.ids = ids
            nextIndex = min(Self.pageSize, ids.count)
            stories = page
            phase = .loaded
        } catch is CancellationError {
        } catch {
            guard feed == self.feed else { return }
            phase = .failed(error.localizedDescription)
        }
    }

    /// Appends the next page. Safe to call repeatedly; extra calls are ignored.
    func loadMore() async {
        guard hasMore, !isLoadingMore, phase == .loaded else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        let feed = feed
        let range = nextIndex..<min(nextIndex + Self.pageSize, ids.count)
        do {
            let page = try await client.stories(ids: Array(ids[range]))
            guard feed == self.feed else { return }
            let seen = Set(stories.map(\.id))
            stories += page.filter { !seen.contains($0.id) }
            nextIndex = range.upperBound
        } catch {
            // Leave nextIndex alone so scrolling to the end retries.
        }
    }
}
