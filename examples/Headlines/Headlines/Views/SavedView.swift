import SafariServices
import SwiftData
import SwiftUI

struct SavedView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Bookmark.savedAt, order: .reverse) private var bookmarks: [Bookmark]
    @State private var openPage: WebPage?

    var body: some View {
        NavigationStack {
            List {
                ForEach(bookmarks) { bookmark in
                    Button {
                        openPage = WebPage(url: bookmark.link)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bookmark.title).font(.body.weight(.medium))
                            HStack {
                                if let domain = bookmark.domain { Text(domain) }
                                Text("Saved \(bookmark.savedAt.formatted(.relative(presentation: .named)))")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Open Comments", systemImage: "bubble.left") { openPage = WebPage(url: bookmark.discussionURL) }
                        ShareLink(item: bookmark.link)
                    }
                }
                .onDelete { offsets in
                    offsets.map { bookmarks[$0] }.forEach(context.delete)
                }
            }
            .listStyle(.plain)
            .overlay {
                if bookmarks.isEmpty {
                    ContentUnavailableView(
                        "Nothing Saved",
                        systemImage: "bookmark",
                        description: Text("Swipe left on a story to save it for later.")
                    )
                }
            }
            .navigationTitle("Saved")
            .sheet(item: $openPage) { SafariView(url: $0.url).ignoresSafeArea() }
        }
    }
}

/// Shows a web page in-app with Safari's reader, sharing, and sign-in.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
