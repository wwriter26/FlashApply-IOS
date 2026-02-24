import SwiftUI

struct LocationsSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showAdd = false

    var locations: [PreferredLocation] { profileVM.profile.jobPreferences?.locations ?? [] }

    var body: some View {
        List {
            ForEach(locations) { loc in
                HStack {
                    Image(systemName: "mappin.circle.fill").foregroundColor(.flashTeal)
                    Text([loc.city, loc.state, loc.country].compactMap { $0 }.joined(separator: ", "))
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { delete(id: loc.id) } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Preferred Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) { Image(systemName: "plus") }
                    .foregroundColor(.flashTeal)
            }
        }
        .sheet(isPresented: $showAdd) {
            LocationForm { loc in
                var updated = profileVM.profile
                var prefs = updated.jobPreferences ?? JobPreferences()
                var locs = prefs.locations ?? []
                locs.append(loc)
                prefs.locations = locs
                updated.jobPreferences = prefs
                Task { try? await profileVM.updateProfile(updated) }
            }
        }
    }

    private func delete(id: String) {
        var updated = profileVM.profile
        updated.jobPreferences?.locations?.removeAll { $0.id == id }
        Task { try? await profileVM.updateProfile(updated) }
    }
}

struct LocationForm: View {
    let onSave: (PreferredLocation) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var city = ""
    @State private var state = ""
    @State private var country = "United States"

    var body: some View {
        NavigationStack {
            Form {
                TextField("City", text: $city)
                TextField("State / Province", text: $state)
                TextField("Country", text: $country)
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let loc = PreferredLocation(city: city.isEmpty ? nil : city,
                                                    state: state.isEmpty ? nil : state,
                                                    country: country.isEmpty ? nil : country)
                        onSave(loc)
                        dismiss()
                    }
                    .foregroundColor(.flashTeal)
                    .disabled(city.isEmpty && state.isEmpty)
                }
            }
        }
    }
}
