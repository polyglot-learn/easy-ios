import Foundation
import Testing

@testable import Headlines

@MainActor
struct StoryTests {
    @Test func decodesAPIItem() throws {
        let json = Data(
            """
            {"by":"pg","descendants":15,"id":1,"kids":[15,234],"score":57,"time":1160418111,
             "title":"Y Combinator","type":"story","url":"http://www.ycombinator.com"}
            """.utf8)
        let story = try JSONDecoder().decode(Story.self, from: json)
        #expect(story.title == "Y Combinator")
        #expect(story.domain == "ycombinator.com")
        #expect(story.date == Date(timeIntervalSince1970: 1_160_418_111))
        #expect(story.isVisible)
    }

    @Test func askPostsLinkToDiscussion() throws {
        let json = Data(#"{"id":42,"title":"Ask HN: Anything?","time":0,"type":"story"}"#.utf8)
        let story = try JSONDecoder().decode(Story.self, from: json)
        #expect(story.domain == nil)
        #expect(story.link == URL(string: "https://news.ycombinator.com/item?id=42"))
    }

    @Test(arguments: [
        #"{"id":1,"time":0,"deleted":true}"#,
        #"{"id":1,"time":0,"title":"x","dead":true}"#,
        #"{"id":1,"time":0,"title":"x","type":"comment"}"#,
        #"{"id":1,"time":0,"title":""}"#,
    ])
    func hidesItemsThatShouldNotAppear(json: String) throws {
        let story = try JSONDecoder().decode(Story.self, from: Data(json.utf8))
        #expect(!story.isVisible)
    }
}

@MainActor
struct HNClientTests {
    /// Serves IDs 1...n; items respond in reverse order of request to prove ordering is kept.
    func client(count: Int, failing: Set<Int> = []) -> HNClient {
        HNClient { url in
            if url.lastPathComponent.hasSuffix("stories.json") {
                return try JSONEncoder().encode(Array(1...count))
            }
            let id = Int(url.deletingPathExtension().lastPathComponent)!
            try await Task.sleep(for: .milliseconds(count - id))
            if failing.contains(id) { throw URLError(.timedOut) }
            return Data(#"{"id":\#(id),"time":0,"title":"Story \#(id)","type":"story"}"#.utf8)
        }
    }

    @Test func fetchesInParallelButKeepsOrder() async throws {
        let stories = try await client(count: 10).stories(ids: Array(1...10))
        #expect(stories.map(\.id) == Array(1...10))
    }

    @Test func skipsItemsThatFailToLoad() async throws {
        let stories = try await client(count: 5, failing: [2, 4]).stories(ids: Array(1...5))
        #expect(stories.map(\.id) == [1, 3, 5])
    }

    @Test func storeLoadsPagesAndStops() async {
        let store = FeedStore(client: client(count: 45))
        await store.load(.top)
        #expect(store.stories.count == FeedStore.pageSize)
        #expect(store.hasMore)
        await store.loadMore()
        #expect(store.stories.map(\.id) == Array(1...45))
        #expect(!store.hasMore)
        await store.loadMore()
        #expect(store.stories.count == 45)
    }

    @Test func storeReportsFailure() async {
        let store = FeedStore(client: HNClient { _ in throw URLError(.notConnectedToInternet) })
        await store.load(.new)
        guard case .failed = store.phase else {
            Issue.record("expected failure, got \(store.phase)")
            return
        }
    }

    @Test func feedPaths() {
        #expect(Feed.top.path == "topstories")
        #expect(Feed.ask.path == "askstories")
    }
}
