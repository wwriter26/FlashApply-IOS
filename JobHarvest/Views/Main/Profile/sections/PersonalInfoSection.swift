import SwiftUI

struct PersonalInfoSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isSaving = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Name") {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
            }
            Section("Contact") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }
        }
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving..." : "Save") { save() }
                    .foregroundColor(.flashTeal)
                    .disabled(isSaving)
            }
        }
        .onAppear { load() }
        .alert("Saved!", isPresented: $saved) {
            Button("OK") { dismiss() }
        }
    }

    private func load() {
        firstName = profileVM.profile.firstName ?? ""
        lastName  = profileVM.profile.lastName ?? ""
        email     = profileVM.profile.email ?? ""
        phone     = profileVM.profile.phone ?? ""
    }

    private func save() {
        isSaving = true
        var updated = profileVM.profile
        updated.firstName = firstName.isEmpty ? nil : firstName
        updated.lastName  = lastName.isEmpty ? nil : lastName
        updated.email     = email.isEmpty ? nil : email
        updated.phone     = phone.isEmpty ? nil : phone
        Task {
            try? await profileVM.updateProfile(updated)
            isSaving = false
            saved = true
        }
    }
}
