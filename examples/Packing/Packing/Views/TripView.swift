import SwiftData
import SwiftUI

struct TripView: View {
    let trip: Trip

    @Environment(\.modelContext) private var context
    @State private var newItemName = ""
    @State private var newItemCategory = ItemCategory.other
    @State private var hidePacked = false

    private var groups: [(category: ItemCategory, items: [PackingItem])] {
        ItemCategory.allCases.compactMap { category in
            let items = trip.items
                .filter { $0.category == category && !(hidePacked && $0.isPacked) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(trip.packedCount) of \(trip.items.count) packed")
                        .font(.headline)
                        .accessibilityIdentifier("packedSummary")
                    ProgressView(value: trip.progress)
                        .tint(trip.progress >= 1 ? .green : .accentColor)
                    Text("^[\(trip.nights()) night](inflect: true) · \(trip.startDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Add item") {
                HStack {
                    TextField("Item", text: $newItemName)
                        .onSubmit(addItem)
                    Picker("Category", selection: $newItemCategory) {
                        ForEach(ItemCategory.allCases) { Image(systemName: $0.symbol).tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    Button("Add", systemImage: "plus.circle.fill", action: addItem)
                        .labelStyle(.iconOnly)
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            ForEach(groups, id: \.category) { group in
                Section {
                    ForEach(group.items) { item in
                        ItemRow(item: item)
                    }
                    .onDelete { offsets in
                        offsets.map { group.items[$0] }.forEach(context.delete)
                    }
                } header: {
                    Label(group.category.title, systemImage: group.category.symbol)
                }
            }
        }
        .navigationTitle(trip.name)
        .toolbar {
            Toggle("Hide Packed", systemImage: hidePacked ? "eye.slash" : "eye", isOn: $hidePacked.animation())
        }
    }

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        trip.items.append(PackingItem(name: name, category: newItemCategory))
        newItemName = ""
    }
}

private struct ItemRow: View {
    let item: PackingItem

    var body: some View {
        Button {
            withAnimation { item.isPacked.toggle() }
        } label: {
            HStack {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPacked ? Color.green : .secondary)
                    .font(.title3)
                Text(item.name)
                    .strikethrough(item.isPacked)
                    .foregroundStyle(item.isPacked ? .secondary : .primary)
                Spacer()
                if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.quantity > 1 ? "\(item.name), \(item.quantity)" : item.name)
        .accessibilityValue(item.isPacked ? "Packed" : "Not packed")
    }
}
