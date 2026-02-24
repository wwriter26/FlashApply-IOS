import SwiftUI

struct PreferencesSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var jobTypes: [String] = []
    @State private var remoteOnly = false
    @State private var salaryMin: Double = 0
    @State private var isSaving = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    let availableTypes = ["Internship", "Part-Time", "Full-Time", "Contract"]

    var body: some View {
        Form {
            Section("Job Type") {
                ForEach(availableTypes, id: \.self) { type in
                    Toggle(type, isOn: Binding(
                        get: { jobTypes.contains(type) },
                        set: { isOn in
                            if isOn { jobTypes.append(type) } else { jobTypes.removeAll { $0 == type } }
                        }
                    ))
                    .tint(.flashTeal)
                }
            }
            Section("Remote") {
                Toggle("Remote Only", isOn: $remoteOnly).tint(.flashTeal)
            }
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Minimum Salary")
                        Spacer()
                        Text(salaryMin > 0 ? "$\(Int(salaryMin))k" : "None")
                            .foregroundColor(.flashTeal)
                    }
                    Slider(value: $salaryMin, in: 0...250, step: 5)
                        .tint(.flashTeal)
                }
            } header: { Text("Salary") }
        }
        .navigationTitle("Job Preferences")
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
        jobTypes   = profileVM.profile.jobPreferences?.jobTypes ?? []
        remoteOnly = profileVM.profile.jobPreferences?.remoteOnly ?? false
        salaryMin  = profileVM.profile.jobPreferences?.salaryMin ?? 0
    }

    private func save() {
        isSaving = true
        var updated = profileVM.profile
        updated.jobPreferences = JobPreferences(
            jobTypes: jobTypes.isEmpty ? nil : jobTypes,
            salaryMin: salaryMin > 0 ? salaryMin : nil,
            remoteOnly: remoteOnly
        )
        Task {
            try? await profileVM.updateProfile(updated)
            isSaving = false
            saved = true
        }
    }
}
