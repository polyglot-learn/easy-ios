import Foundation

/// Canned stories for previews and UI tests.
nonisolated enum SampleStories {
    static let all: [Story] = {
        let now = Int(Date.now.timeIntervalSince1970)
        let rows: [(Int, String, String?, String, Int, Int, Int)] = [
            (1001, "SwiftUI tips for building your first app", "https://www.example.com/swiftui-tips", "alice", 312, 3600, 87),
            (1002, "Ask HN: What are you learning this year?", nil, "bob", 154, 7200, 203),
            (1003, "Show HN: A tiny habit tracker", "https://github.com/example/habits", "carol", 98, 10_800, 24),
            (1004, "The history of the floppy disk", "https://example.org/floppy", "dave", 76, 14_400, 15),
            (1005, "SQLite is not a toy database", "https://blog.example.net/sqlite", "erin", 420, 18_000, 166),
        ]
        return rows.map { id, title, url, by, score, age, comments in
            Story(
                id: id, title: title, url: url.flatMap(URL.init(string:)), by: by, score: score,
                time: now - age, descendants: comments, type: "story", deleted: nil, dead: nil
            )
        }
    }()

    /// Mirrors the API's JSON shape so the sample client returns real-looking responses.
    struct Encodable: Swift.Encodable {
        let id: Int, title: String?, url: URL?, by: String?, score: Int?, time: Int, descendants: Int?, type: String?

        init(_ s: Story) {
            (id, title, url, by, score, time, descendants, type) = (s.id, s.title, s.url, s.by, s.score, s.time, s.descendants, s.type)
        }
    }
}
