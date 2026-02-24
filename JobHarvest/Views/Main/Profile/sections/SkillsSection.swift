import SwiftUI

struct SkillsSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var newSkill = ""

    var skills: [String] { profileVM.profile.skills ?? [] }

    var body: some View {
        Form {
            Section("Your Skills") {
                if skills.isEmpty {
                    Text("No skills added yet.").foregroundColor(.secondary)
                } else {
                    FlowLayout(items: skills) { skill in
                        HStack(spacing: 4) {
                            Text(skill).font(.callout)
                            Button(action: { removeSkill(skill) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.flashTeal.opacity(0.1))
                        .foregroundColor(.flashTeal)
                        .cornerRadius(20)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Add Skill") {
                HStack {
                    TextField("Skill name", text: $newSkill)
                        .autocapitalization(.words)
                    Button("Add") { addSkill() }
                        .foregroundColor(.flashTeal)
                        .disabled(newSkill.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationTitle("Skills")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addSkill() {
        let skill = newSkill.trimmingCharacters(in: .whitespaces)
        guard !skill.isEmpty, !skills.contains(skill) else { return }
        newSkill = ""
        var updated = profileVM.profile
        var list = updated.skills ?? []
        list.append(skill)
        updated.skills = list
        Task { try? await profileVM.updateProfile(updated) }
    }

    private func removeSkill(_ skill: String) {
        var updated = profileVM.profile
        updated.skills?.removeAll { $0 == skill }
        Task { try? await profileVM.updateProfile(updated) }
    }
}
