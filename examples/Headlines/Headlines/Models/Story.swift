import Foundation

/// A Hacker News item. Most fields are optional in the API.
nonisolated struct Story: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String?
    let url: URL?
    let by: String?
    let score: Int?
    let time: Int
    let descendants: Int?
    let type: String?
    let deleted: Bool?
    let dead: Bool?

    var date: Date { Date(timeIntervalSince1970: TimeInterval(time)) }

    /// The HN comments page.
    var discussionURL: URL { URL(string: "https://news.ycombinator.com/item?id=\(id)")! }

    /// Where tapping the story goes: the article, or the discussion for Ask HN posts.
    var link: URL { url ?? discussionURL }

    /// "example.com" for the article link, without "www.".
    var domain: String? {
        guard let host = url?.host() else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// Whether the item should appear in a feed.
    var isVisible: Bool {
        deleted != true && dead != true && title?.isEmpty == false && (type == nil || type == "story" || type == "job" || type == "poll")
    }
}

nonisolated enum Feed: String, CaseIterable, Identifiable {
    case top, new, best, ask, show

    var id: Self { self }

    var title: String {
        switch self {
        case .top: String(localized: "Top")
        case .new: String(localized: "New")
        case .best: String(localized: "Best")
        case .ask: String(localized: "Ask")
        case .show: String(localized: "Show")
        }
    }

    var path: String { "\(rawValue)stories" }
}
