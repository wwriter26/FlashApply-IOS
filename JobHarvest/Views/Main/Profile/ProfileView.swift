import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                // Completion bar
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Profile Completion")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(profileVM.profile.completionPercentage)%")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.flashTeal)
                        }
                        ProgressView(value: Double(profileVM.profile.completionPercentage), total: 100)
                            .tint(.flashTeal)
                    }
                    .padding(.vertical, 4)
                }

                // Sections
                Section("Personal") {
                    NavigationLink(destination: PersonalInfoSection().environmentObject(profileVM)) {
                        profileRow(icon: "person.fill", title: "Personal Info",
                                   subtitle: profileVM.profile.firstName.map { "\($0) \(profileVM.profile.lastName ?? "")" })
                    }
                    NavigationLink(destination: AddressSection().environmentObject(profileVM)) {
                        profileRow(icon: "house.fill", title: "Address",
                                   subtitle: profileVM.profile.city)
                    }
                    NavigationLink(destination: AuthorizationsSection().environmentObject(profileVM)) {
                        profileRow(icon: "checkmark.shield.fill", title: "Work Authorization",
                                   subtitle: profileVM.profile.workAuthorization)
                    }
                }

                Section("Experience") {
                    NavigationLink(destination: WorkHistorySection().environmentObject(profileVM)) {
                        profileRow(icon: "briefcase.fill", title: "Work History",
                                   subtitle: "\(profileVM.profile.workHistory?.count ?? 0) entries")
                    }
                    NavigationLink(destination: EducationSection().environmentObject(profileVM)) {
                        profileRow(icon: "graduationcap.fill", title: "Education",
                                   subtitle: "\(profileVM.profile.education?.count ?? 0) entries")
                    }
                    NavigationLink(destination: SkillsSection().environmentObject(profileVM)) {
                        profileRow(icon: "star.fill", title: "Skills",
                                   subtitle: "\(profileVM.profile.skills?.count ?? 0) skills")
                    }
                    NavigationLink(destination: CertificationsSection().environmentObject(profileVM)) {
                        profileRow(icon: "rosette", title: "Certifications",
                                   subtitle: "\(profileVM.profile.certifications?.count ?? 0) entries")
                    }
                }

                Section("Profile") {
                    NavigationLink(destination: ResumeSection().environmentObject(profileVM)) {
                        profileRow(icon: "doc.fill", title: "Resume",
                                   subtitle: profileVM.profile.resumeFileName ?? "Not uploaded")
                    }
                    NavigationLink(destination: LinksSection().environmentObject(profileVM)) {
                        profileRow(icon: "link", title: "Links & Portfolio",
                                   subtitle: profileVM.profile.linkedIn ?? "Not set")
                    }
                }

                Section("Preferences") {
                    NavigationLink(destination: PreferencesSection().environmentObject(profileVM)) {
                        profileRow(icon: "slider.horizontal.3", title: "Job Preferences",
                                   subtitle: profileVM.profile.jobPreferences?.jobTypes?.joined(separator: ", "))
                    }
                    NavigationLink(destination: LocationsSection().environmentObject(profileVM)) {
                        profileRow(icon: "mappin.circle.fill", title: "Preferred Locations",
                                   subtitle: "\(profileVM.profile.jobPreferences?.locations?.count ?? 0) locations")
                    }
                }

                Section("Additional") {
                    NavigationLink(destination: EEOSection().environmentObject(profileVM)) {
                        profileRow(icon: "person.2.fill", title: "EEO Information",
                                   subtitle: "Optional")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await profileVM.fetchProfile() }
            .task {
                if !profileVM.isLoaded {
                    await profileVM.fetchProfile()
                }
            }
        }
    }

    private func profileRow(icon: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.flashTeal)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.medium))
                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
