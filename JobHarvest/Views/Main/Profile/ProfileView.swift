import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showSaveSuccess = false

    var body: some View {
        NavigationStack {
            Group {
                if profileVM.isLoading && !profileVM.isLoaded {
                    LoadingView(message: "Loading profile...")
                } else {
                    profileContent
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if !profileVM.isLoaded {
                await profileVM.fetchProfile()
            }
        }
    }

    private var profileContent: some View {
        List {
            // Error banner
            if let errorMsg = profileVM.error {
                Section {
                    ErrorBannerView(message: errorMsg) {
                        profileVM.error = nil
                        Task { await profileVM.fetchProfile() }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            // Save success banner
            if showSaveSuccess {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    Text("Changes saved successfully")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#00c97a"), Color(hex: "#00b36b")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color(hex: "#00c97a").opacity(0.3), radius: 8, x: 0, y: 4)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

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

                    let missing = profileVM.profile.missingFields
                    if !missing.isEmpty {
                        Text("Missing: \(missing.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 4)
            }

            // Personal
            Section("Personal") {
                NavigationLink(destination: PersonalInfoSection().environmentObject(profileVM)) {
                    profileRow(icon: "person.fill", title: "Personal Info",
                               subtitle: profileVM.profile.firstName.map { "\($0) \(profileVM.profile.lastName ?? "")" },
                               isMissing: profileVM.profile.firstName == nil)
                }
                NavigationLink(destination: AddressSection().environmentObject(profileVM)) {
                    profileRow(icon: "house.fill", title: "Address",
                               subtitle: [profileVM.profile.city, profileVM.profile.state].compactMap { $0 }.joined(separator: ", ").nilIfEmpty,
                               isMissing: profileVM.profile.city == nil && profileVM.profile.address == nil)
                }
                NavigationLink(destination: AuthorizationsSection().environmentObject(profileVM)) {
                    profileRow(icon: "checkmark.shield.fill", title: "Work Authorization",
                               subtitle: profileVM.profile.authorizedToWorkInUS ?? profileVM.profile.workAuthorization,
                               isMissing: profileVM.profile.authorizedToWorkInUS == nil && profileVM.profile.workAuthorization == nil)
                }
            }

            // Experience
            Section("Experience") {
                NavigationLink(destination: WorkHistorySection().environmentObject(profileVM)) {
                    profileRow(icon: "briefcase.fill", title: "Work History",
                               subtitle: "\(profileVM.profile.workHistory?.count ?? 0) entries",
                               isMissing: profileVM.profile.workHistory?.isEmpty ?? true)
                }
                NavigationLink(destination: EducationSection().environmentObject(profileVM)) {
                    profileRow(icon: "graduationcap.fill", title: "Education",
                               subtitle: "\(profileVM.profile.education?.count ?? 0) entries",
                               isMissing: profileVM.profile.educationHistory?.isEmpty ?? true)
                }
                NavigationLink(destination: SkillsSection().environmentObject(profileVM)) {
                    profileRow(icon: "star.fill", title: "Skills",
                               subtitle: "\(profileVM.profile.skills?.count ?? 0) skills",
                               isMissing: profileVM.profile.skills?.isEmpty ?? true)
                }
                NavigationLink(destination: CertificationsSection().environmentObject(profileVM)) {
                    profileRow(icon: "rosette", title: "Certifications",
                               subtitle: "\(profileVM.profile.certifications?.count ?? 0) entries")
                }
            }

            // Profile
            Section("Profile") {
                NavigationLink(destination: ResumeSection().environmentObject(profileVM)) {
                    profileRow(icon: "doc.fill", title: "Resume",
                               subtitle: profileVM.profile.resumeFileName ?? "Not uploaded",
                               isMissing: profileVM.profile.resumeFileName == nil)
                }
                NavigationLink(destination: LinksSection().environmentObject(profileVM)) {
                    profileRow(icon: "link", title: "Links & Portfolio",
                               subtitle: profileVM.profile.linkedIn ?? "Not set",
                               isMissing: profileVM.profile.linkedIn == nil || profileVM.profile.linkedIn?.isEmpty == true)
                }
            }

            // Preferences
            Section("Preferences") {
                NavigationLink(destination: PreferencesSection().environmentObject(profileVM)) {
                    profileRow(icon: "slider.horizontal.3", title: "Job Preferences",
                               subtitle: profileVM.profile.jobPreferences?.jobTypes?.joined(separator: ", "))
                }
                NavigationLink(destination: LocationsSection().environmentObject(profileVM)) {
                    profileRow(icon: "mappin.circle.fill", title: "Preferred Locations",
                               subtitle: "\(profileVM.profile.preferredJobLocations?.count ?? profileVM.profile.jobPreferences?.locations?.count ?? 0) locations")
                }
            }

            // Additional
            Section("Additional") {
                NavigationLink(destination: EEOSection().environmentObject(profileVM)) {
                    profileRow(icon: "person.2.fill", title: "EEO Information",
                               subtitle: "Optional")
                }
            }
        }
        .refreshable { await profileVM.fetchProfile() }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidSave)) { _ in
            withAnimation { showSaveSuccess = true }
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation { showSaveSuccess = false }
            }
        }
    }

    private func profileRow(icon: String, title: String, subtitle: String?, isMissing: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.flashTeal)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.subheadline.weight(.medium))
                    if isMissing {
                        Text("Missing")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
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

// MARK: - Helper
private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
