import Foundation

/// The official Hacker News API (free, no key). `fetch` is swappable so
/// previews and UI tests can use canned data. Nonisolated so requests and
/// decoding run off the main actor.
nonisolated struct HNClient: Sendable {
    var fetch: @Sendable (URL) async throws -> Data

    static let base = URL(string: "https://hacker-news.firebaseio.com/v0/")!

    static let live = HNClient { url in
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    static let sample = HNClient { url in
        if url.lastPathComponent.hasSuffix("stories.json") {
            return try JSONEncoder().encode(SampleStories.all.map(\.id))
        }
        let id = Int(url.deletingPathExtension().lastPathComponent)
        guard let story = SampleStories.all.first(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        return try JSONEncoder().encode(SampleStories.Encodable(story))
    }

    func storyIDs(_ feed: Feed) async throws -> [Int] {
        let data = try await fetch(Self.base.appending(path: "\(feed.path).json"))
        return try JSONDecoder().decode([Int].self, from: data)
    }

    /// Fetches items in parallel, keeping the order of `ids`. Items that fail
    /// to load, or that are deleted or dead, are left out rather than failing the page.
    func stories(ids: [Int]) async throws -> [Story] {
        let fetch = fetch
        let loaded = try await withThrowingTaskGroup(of: (Int, Story?).self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask {
                    let url = Self.base.appending(path: "item/\(id).json")
                    let story = try? JSONDecoder().decode(Story.self, from: await fetch(url))
                    return (index, story)
                }
            }
            var results = [Story?](repeating: nil, count: ids.count)
            for try await (index, story) in group { results[index] = story }
            return results
        }
        try Task.checkCancellation()
        return loaded.compactMap { $0 }.filter(\.isVisible)
    }
}
