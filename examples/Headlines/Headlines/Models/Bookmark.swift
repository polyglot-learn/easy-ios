import Foundation
import SwiftData

/// A saved story, stored locally so it's readable offline in the list.
@Model
final class Bookmark {
    var storyID: Int
    var title: String
    var link: URL
    var domain: String?
    var savedAt: Date

    init(_ story: Story, savedAt: Date = .now) {
        storyID = story.id
        title = story.title ?? ""
        link = story.link
        domain = story.domain
        self.savedAt = savedAt
    }

    var discussionURL: URL { URL(string: "https://news.ycombinator.com/item?id=\(storyID)")! }
}
