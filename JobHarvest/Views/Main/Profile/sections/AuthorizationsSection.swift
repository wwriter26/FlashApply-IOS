import SwiftUI

struct AuthorizationsSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var workAuth = "US Citizen"
    @State private var requiresSponsorship = false
    @State private var isSaving = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    let options = ["US Citizen", "Permanent Resident (Green Card)", "H-1B Visa",
                   "OPT", "CPT", "TN Visa", "Other Work Visa", "Not Authorized"]

    var body: some View {
        Form {
            Section("Work Authorization Status") {
                Picker("Status", selection: $workAuth) {
                    ForEach(options, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.inline)
            }
            Section("Sponsorship") {
                Toggle("Requires Visa Sponsorship", isOn: $requiresSponsorship)
                    .tint(.flashTeal)
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
        workAuth = profileVM.profile.workAuthorization ?? "US Citizen"
        requiresSponsorship = profileVM.profile.sponsorship ?? false
    }

    private func save() {
        isSaving = true
        var updated = profileVM.profile
        updated.workAuthorization = workAuth
        updated.sponsorship = requiresSponsorship
        Task {
            try? await profileVM.updateProfile(updated)
            isSaving = false
            saved = true
        }
    }
}
