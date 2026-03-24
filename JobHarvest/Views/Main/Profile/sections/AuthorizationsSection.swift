import SwiftUI

struct AuthorizationsSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var authorizedUS = "Yes"
    @State private var authorizedCA = "No"
    @State private var isUsCitizen = "Yes"
    @State private var requiresSponsorship = "No"
    @State private var securityClearance = ""
    @State private var isSaving = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("US Work Authorization") {
                Picker("Authorized to work in US", selection: $authorizedUS) {
                    Text("Yes").tag("Yes")
                    Text("No").tag("No")
                }
                .pickerStyle(.segmented)

                Picker("US Citizen", selection: $isUsCitizen) {
                    Text("Yes").tag("Yes")
                    Text("No").tag("No")
                }
                .pickerStyle(.segmented)
            }

            Section("Canada") {
                Picker("Authorized to work in Canada", selection: $authorizedCA) {
                    Text("Yes").tag("Yes")
                    Text("No").tag("No")
                }
                .pickerStyle(.segmented)
            }

            Section("Sponsorship") {
                Picker("Requires Visa Sponsorship", selection: $requiresSponsorship) {
                    Text("Yes").tag("Yes")
                    Text("No").tag("No")
                }
                .pickerStyle(.segmented)
            }

            Section("Security Clearance") {
                TextField("Security Clearance (if any)", text: $securityClearance)
            }
        }
        .navigationTitle("Work Authorization")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving..." : "Save") { save() }
                    .foregroundColor(.flashTeal).disabled(isSaving)
            }
        }
        .onAppear { load() }
        .alert("Saved!", isPresented: $saved) { Button("OK") { dismiss() } }
    }

    private func load() {
        authorizedUS = profileVM.profile.authorizedToWorkInUS ?? "Yes"
        authorizedCA = profileVM.profile.authorizedToWorkInCA ?? "No"
        isUsCitizen = profileVM.profile.isUsCitizen ?? "Yes"
        requiresSponsorship = profileVM.profile.sponsorship ?? "No"
        securityClearance = profileVM.profile.securityClearance ?? ""
    }

    private func save() {
        isSaving = true
        var updated = profileVM.profile
        updated.authorizedToWorkInUS = authorizedUS
        updated.authorizedToWorkInCA = authorizedCA
        updated.isUsCitizen = isUsCitizen
        updated.sponsorship = requiresSponsorship
        updated.securityClearance = securityClearance.isEmpty ? nil : securityClearance
        Task {
            try? await profileVM.updateProfile(updated)
            isSaving = false
            saved = true
        }
    }
}
