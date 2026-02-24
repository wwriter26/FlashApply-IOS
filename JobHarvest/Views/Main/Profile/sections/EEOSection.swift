import SwiftUI

struct EEOSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var gender = ""
    @State private var ethnicity = ""
    @State private var veteranStatus = ""
    @State private var disabilityStatus = ""
    @State private var isSaving = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("These questions are optional and voluntary. Providing this information helps employers meet equal opportunity requirements.")
                    .font(.caption).foregroundColor(.secondary)
            }
            Section("Gender") {
                Picker("Gender", selection: $gender) {
                    Text("Prefer not to say").tag("")
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Non-binary").tag("Non-binary")
                    Text("Other").tag("Other")
                }
            }
            Section("Ethnicity") {
                Picker("Ethnicity", selection: $ethnicity) {
                    Text("Prefer not to say").tag("")
                    Text("White").tag("White")
                    Text("Black or African American").tag("Black or African American")
                    Text("Hispanic or Latino").tag("Hispanic or Latino")
                    Text("Asian").tag("Asian")
                    Text("Native American").tag("Native American")
                    Text("Two or More Races").tag("Two or More Races")
                    Text("Other").tag("Other")
                }
            }
            Section("Veteran Status") {
                Picker("Veteran", selection: $veteranStatus) {
                    Text("Prefer not to say").tag("")
                    Text("Not a Veteran").tag("Not a Veteran")
                    Text("Protected Veteran").tag("Protected Veteran")
                    Text("Not a Protected Veteran").tag("Not a Protected Veteran")
                }
            }
            Section("Disability Status") {
                Picker("Disability", selection: $disabilityStatus) {
                    Text("Prefer not to say").tag("")
                    Text("No Disability").tag("No Disability")
                    Text("Yes, I have a Disability").tag("Yes, I have a Disability")
                }
            }
        }
        .navigationTitle("EEO Information")
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
        gender           = profileVM.profile.eeo?.gender ?? ""
        ethnicity        = profileVM.profile.eeo?.ethnicity ?? ""
        veteranStatus    = profileVM.profile.eeo?.veteranStatus ?? ""
        disabilityStatus = profileVM.profile.eeo?.disabilityStatus ?? ""
    }

    private func save() {
        isSaving = true
        var updated = profileVM.profile
        updated.eeo = EEOData(
            gender: gender.isEmpty ? nil : gender,
            ethnicity: ethnicity.isEmpty ? nil : ethnicity,
            veteranStatus: veteranStatus.isEmpty ? nil : veteranStatus,
            disabilityStatus: disabilityStatus.isEmpty ? nil : disabilityStatus
        )
        Task {
            try? await profileVM.updateProfile(updated)
            isSaving = false
            saved = true
        }
    }
}
