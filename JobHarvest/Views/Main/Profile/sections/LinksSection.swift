import SwiftUI

struct LinksSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var linkedIn = ""
    @State private var github = ""
    @State private var portfolio = ""
    @State private var isSaving = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Professional Links") {
                HStack {
                    Image(systemName: "link.circle.fill").foregroundColor(.blue)
                    TextField("LinkedIn URL", text: $linkedIn)
                        .keyboardType(.URL).autocapitalization(.none)
                }
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right").foregroundColor(.black)
                    TextField("GitHub URL", text: $github)
                        .keyboardType(.URL).autocapitalization(.none)
                }
                HStack {
                    Image(systemName: "globe").foregroundColor(.flashTeal)
                    TextField("Portfolio / Website URL", text: $portfolio)
                        .keyboardType(.URL).autocapitalization(.none)
                }
            }
        }
        .navigationTitle("Links")
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
        linkedIn  = profileVM.profile.linkedIn ?? ""
        github    = profileVM.profile.github ?? ""
        portfolio = profileVM.profile.portfolio ?? ""
    }

    private func save() {
        isSaving = true
        var updated = profileVM.profile
        updated.linkedIn  = linkedIn.isEmpty ? nil : linkedIn
        updated.github    = github.isEmpty ? nil : github
        updated.portfolio = portfolio.isEmpty ? nil : portfolio
        Task {
            try? await profileVM.updateProfile(updated)
            isSaving = false
            saved = true
        }
    }
}
