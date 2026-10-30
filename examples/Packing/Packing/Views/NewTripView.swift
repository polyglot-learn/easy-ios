import SwiftData
import SwiftUI

struct NewTripView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startDate = Calendar.current.date(byAdding: .day, value: 7, to: .now)!
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 10, to: .now)!
    @State private var climate = Climate.mild
    @State private var activities: Set<Activity> = []
    @State private var includeSuggestions = true

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Destination", text: $name)
                    DatePicker("Leaving", selection: $startDate, displayedComponents: .date)
                    DatePicker("Returning", selection: $endDate, in: startDate..., displayedComponents: .date)
                } footer: {
                    Text("^[\(Trip.nights(from: startDate, to: endDate, calendar: .current)) night](inflect: true)")
                }

                Section {
                    Toggle("Suggest a packing list", isOn: $includeSuggestions.animation())
                    if includeSuggestions {
                        Picker("Weather", selection: $climate) {
                            ForEach(Climate.allCases) { Text($0.title).tag($0) }
                        }
                        ForEach(Activity.allCases) { activity in
                            Toggle(
                                activity.title,
                                isOn: Binding(
                                    get: { activities.contains(activity) },
                                    set: { if $0 { activities.insert(activity) } else { activities.remove(activity) } }
                                ))
                        }
                    }
                } footer: {
                    if includeSuggestions {
                        Text("Clothing is based on the number of nights, up to a week's worth.")
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create).disabled(trimmedName.isEmpty)
                }
            }
            .onChange(of: startDate) { _, newStart in
                if endDate < newStart { endDate = newStart }
            }
        }
    }

    private func create() {
        let trip = Trip(name: trimmedName, startDate: startDate, endDate: endDate)
        context.insert(trip)
        if includeSuggestions {
            trip.addSuggestions(climate: climate, activities: activities)
        }
        dismiss()
    }
}
