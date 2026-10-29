import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StoriesView()
                .tabItem { Label("Stories", systemImage: "newspaper") }
            SavedView()
                .tabItem { Label("Saved", systemImage: "bookmark") }
        }
    }
}

struct StoriesView: View {
    @Environment(FeedStore.self) private var feed
    @Environment(\.modelContext) private var context
    @Query private var bookmarks: [Bookmark]
    @State private var selectedFeed = Feed.top
    @State private var openPage: WebPage?

    var body: some View {
        NavigationStack {
            List {
                ForEach(feed.stories) { story in
                    let saved = bookmarks.contains { $0.storyID == story.id }
                    StoryRow(story: story, isSaved: saved) { openPage = WebPage(url: $0) }
                        .swipeActions {
                            Button(saved ? "Unsave" : "Save", systemImage: saved ? "bookmark.slash" : "bookmark") {
                                toggleBookmark(story)
                            }
                            .tint(.orange)
                        }
                        .task {
                            // Load the next page when the last rows come into view.
                            if story.id == feed.stories.last?.id { await feed.loadMore() }
                        }
                }
                if feed.isLoadingMore {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            .listStyle(.plain)
            .overlay { overlay }
            .navigationTitle(selectedFeed.title)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Feed", selection: $selectedFeed) {
                        ForEach(Feed.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selectedFeed) { await feed.load(selectedFeed) }
            .refreshable { await feed.load(selectedFeed) }
            .sheet(item: $openPage) { SafariView(url: $0.url).ignoresSafeArea() }
        }
    }

    @ViewBuilder private var overlay: some View {
        switch feed.phase {
        case .idle, .loading:
            if feed.stories.isEmpty { ProgressView() }
        case .failed(let message):
            if feed.stories.isEmpty {
                ContentUnavailableView {
                    Label("Couldn't Load Stories", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await feed.load(selectedFeed) } }
                }
            }
        case .loaded:
            if feed.stories.isEmpty {
                ContentUnavailableView("No Stories", systemImage: "newspaper")
            }
        }
    }

    private func toggleBookmark(_ story: Story) {
        if let existing = bookmarks.first(where: { $0.storyID == story.id }) {
            context.delete(existing)
        } else {
            context.insert(Bookmark(story))
        }
    }
}

struct StoryRow: View {
    let story: Story
    let isSaved: Bool
    let open: (URL) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                open(story.link)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.title ?? "")
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 10) {
                        if let domain = story.domain { Text(domain) }
                        if let score = story.score { Label("\(score)", systemImage: "arrow.up") }
                        Text(story.date, format: .relative(presentation: .named))
                        if isSaved {
                            Image(systemName: "bookmark.fill").foregroundStyle(.orange).accessibilityLabel("Saved")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                open(story.discussionURL)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "bubble.left")
                    Text("\(story.descendants ?? 0)").font(.caption2.monospacedDigit())
                }
                .foregroundStyle(Color.accentColor)
                .frame(minWidth: 36)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("^[\(story.descendants ?? 0) comment](inflect: true)")
        }
        .padding(.vertical, 4)
    }
}

/// A page to show in `SafariView`; wraps the URL so it can drive `.sheet(item:)`.
struct WebPage: Identifiable {
    let url: URL
    var id: URL { url }
}

#Preview {
    ContentView()
        .environment(FeedStore(client: .sample))
        .modelContainer(for: Bookmark.self, inMemory: true)
}
