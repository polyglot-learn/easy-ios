import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @State private var searchText = ""
    @State private var favoritesOnly = false
    @State private var isAdding = false

    private var visibleRecipes: [Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return recipes.filter { recipe in
            (!favoritesOnly || recipe.isFavorite)
                && (query.isEmpty
                    || recipe.name.localizedStandardContains(query)
                    || recipe.ingredients.contains { $0.localizedStandardContains(query) })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(visibleRecipes) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeRow(recipe: recipe)
                    }
                    .swipeActions(edge: .leading) {
                        Button(recipe.isFavorite ? "Unfavorite" : "Favorite", systemImage: recipe.isFavorite ? "heart.slash" : "heart") {
                            recipe.isFavorite.toggle()
                        }
                        .tint(.pink)
                    }
                }
                .onDelete { offsets in
                    offsets.map { visibleRecipes[$0] }.forEach(context.delete)
                }
            }
            .overlay {
                if visibleRecipes.isEmpty {
                    if !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else if favoritesOnly {
                        ContentUnavailableView(
                            "No Favorites", systemImage: "heart", description: Text("Swipe right on a recipe to favorite it."))
                    } else {
                        ContentUnavailableView(
                            "No Recipes", systemImage: "fork.knife", description: Text("Tap + to save your first recipe."))
                    }
                }
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .searchable(text: $searchText, prompt: "Recipes or ingredients")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Toggle("Favorites Only", systemImage: favoritesOnly ? "heart.fill" : "heart", isOn: $favoritesOnly)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Recipe", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) { RecipeEditor(recipe: nil) }
        }
    }
}

private struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(recipe.name).font(.headline)
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                        .font(.caption)
                        .accessibilityLabel("Favorite")
                }
            }
            if !recipe.summary.isEmpty {
                Text(recipe.summary).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            HStack(spacing: 12) {
                if recipe.totalMinutes > 0 {
                    Label(recipe.totalMinutes.durationText, systemImage: "clock")
                }
                Label("^[\(recipe.servings) serving](inflect: true)", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
