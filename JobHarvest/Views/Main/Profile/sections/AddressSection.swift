import SwiftUI

struct AddressSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = "United States"
    @State private var isSaving = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Address") {
                TextField("Street Address", text: $street)
                    .textContentType(.streetAddressLine1)
                TextField("City", text: $city)
                    .textContentType(.addressCity)
                TextField("State", text: $state)
                    .textContentType(.addressState)
                TextField("ZIP Code", text: $zipCode)
                    .keyboardType(.numberPad)
                    .textContentType(.postalCode)
                TextField("Country", text: $country)
                    .textContentType(.countryName)
            }
        }
        .navigationTitle("Address")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving..." : "Save") { save() }
                    .foregroundColor(.flashTeal)
                    .disabled(isSaving)
            }
        }
        .onAppear { load() }
        .alert("Saved!", isPresented: $saved) { Button("OK") { dismiss() } }
    }

    private func load() {
        street  = profileVM.profile.street ?? ""
        city    = profileVM.profile.city ?? ""
        state   = profileVM.profile.state ?? ""
        zipCode = profileVM.profile.zipCode ?? ""
        country = profileVM.profile.country ?? "United States"
    }

    private func save() {
        isSaving = true
        var updated = profileVM.profile
        updated.street  = street.isEmpty ? nil : street
        updated.city    = city.isEmpty ? nil : city
        updated.state   = state.isEmpty ? nil : state
        updated.zipCode = zipCode.isEmpty ? nil : zipCode
        updated.country = country.isEmpty ? nil : country
        Task {
            try? await profileVM.updateProfile(updated)
            isSaving = false
            saved = true
        }
    }
}
