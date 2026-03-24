import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PreferencesQuizView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var currentStep = 0
    @State private var isSubmitting = false
    @State private var error: String?

    // Quiz state
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var workAuth = "US Citizen"
    @State private var requiresSponsorship = "No"
    @State private var skills: [String] = []
    @State private var jobTypes: [String] = []
    @State private var remoteOnly = false
    @State private var resumeData: Data?
    @State private var resumeFileName = ""
    @State private var showDocumentPicker = false
    @State private var showSkipConfirm = false

    private let totalSteps = 5
    private let workAuthOptions = ["US Citizen", "Green Card", "H-1B Visa", "OPT/CPT", "Other"]
    private let suggestedSkills = [
        "Python", "JavaScript", "TypeScript", "Swift", "Java", "C++", "SQL", "Go", "Rust",
        "React", "Node.js", "AWS", "Docker", "Kubernetes",
        "Machine Learning", "Data Analysis", "Excel",
        "Project Management", "Product Management",
        "Communication", "Leadership", "Marketing",
        "UI/UX Design", "Figma", "Adobe Creative Suite"
    ]

    // MARK: - UserDefaults Keys
    private enum QuizKeys {
        static let currentStep = "quiz_currentStep"
        static let firstName = "quiz_firstName"
        static let lastName = "quiz_lastName"
        static let phone = "quiz_phone"
        static let workAuth = "quiz_workAuth"
        static let requiresSponsorship = "quiz_requiresSponsorship"
        static let skills = "quiz_skills"
        static let jobTypes = "quiz_jobTypes"
        static let remoteOnly = "quiz_remoteOnly"
        static let resumeFileName = "quiz_resumeFileName"
    }

    static func clearSavedQuizState() {
        let defaults = UserDefaults.standard
        [QuizKeys.currentStep, QuizKeys.firstName, QuizKeys.lastName,
         QuizKeys.phone, QuizKeys.workAuth, QuizKeys.requiresSponsorship,
         QuizKeys.skills, QuizKeys.jobTypes, QuizKeys.remoteOnly,
         QuizKeys.resumeFileName].forEach { defaults.removeObject(forKey: $0) }
    }

    var body: some View {
        quizStackWithPersistence
    }

    private var quizStackWithSheet: some View {
        quizStack
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView(allowedTypes: [.pdf]) { url in
                    if let data = try? Data(contentsOf: url) {
                        resumeData = data
                        resumeFileName = url.lastPathComponent
                    }
                }
            }
    }

    private var quizStackWithPersistenceA: some View {
        quizStackWithSheet
            .onAppear(perform: restoreQuizState)
            .onChange(of: currentStep) { v in UserDefaults.standard.set(v, forKey: QuizKeys.currentStep) }
            .onChange(of: firstName) { v in UserDefaults.standard.set(v, forKey: QuizKeys.firstName) }
            .onChange(of: lastName) { v in UserDefaults.standard.set(v, forKey: QuizKeys.lastName) }
            .onChange(of: phone) { v in UserDefaults.standard.set(v, forKey: QuizKeys.phone) }
            .onChange(of: workAuth) { v in UserDefaults.standard.set(v, forKey: QuizKeys.workAuth) }
    }

    private var quizStackWithPersistence: some View {
        quizStackWithPersistenceA
            .onChange(of: requiresSponsorship) { v in UserDefaults.standard.set(v, forKey: QuizKeys.requiresSponsorship) }
            .onChange(of: skills) { v in UserDefaults.standard.set(v, forKey: QuizKeys.skills) }
            .onChange(of: jobTypes) { v in UserDefaults.standard.set(v, forKey: QuizKeys.jobTypes) }
            .onChange(of: remoteOnly) { v in UserDefaults.standard.set(v, forKey: QuizKeys.remoteOnly) }
            .onChange(of: resumeFileName) { v in UserDefaults.standard.set(v, forKey: QuizKeys.resumeFileName) }
    }

    private var quizStack: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                progressBar

                // Step content
                TabView(selection: $currentStep) {
                    step1_Resume.tag(0)
                    step2_Name.tag(1)
                    step3_Contact.tag(2)
                    step4_WorkAuth.tag(3)
                    step5_Preferences.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .background(Color.flashBackground.ignoresSafeArea())
            .navigationTitle("Set Up Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        showSkipConfirm = true
                    }
                    .foregroundColor(.flashTextSecondary)
                }
            }
            .confirmationDialog("Skip Profile Setup?", isPresented: $showSkipConfirm, titleVisibility: .visible) {
                Button("Skip for Now") {
                    PreferencesQuizView.clearSavedQuizState()
                    Task { await authVM.markOnboardingComplete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to upload a resume before you can start swiping on jobs. You can complete your profile anytime from the Profile tab.")
            }
        }
    }

    private func restoreQuizState() {
        let defaults = UserDefaults.standard
        currentStep = defaults.integer(forKey: QuizKeys.currentStep)
        firstName = defaults.string(forKey: QuizKeys.firstName) ?? ""
        lastName = defaults.string(forKey: QuizKeys.lastName) ?? ""
        phone = defaults.string(forKey: QuizKeys.phone) ?? ""
        workAuth = defaults.string(forKey: QuizKeys.workAuth) ?? "US Citizen"
        requiresSponsorship = defaults.string(forKey: QuizKeys.requiresSponsorship) ?? "No"
        skills = defaults.stringArray(forKey: QuizKeys.skills) ?? []
        jobTypes = defaults.stringArray(forKey: QuizKeys.jobTypes) ?? []
        remoteOnly = defaults.bool(forKey: QuizKeys.remoteOnly)
        resumeFileName = defaults.string(forKey: QuizKeys.resumeFileName) ?? ""
        // Note: resumeData (binary) is NOT persisted -- user must re-select PDF after force-quit
        // But resumeFileName is preserved so the UI shows the previous selection name
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 4)
                Rectangle()
                    .fill(Color.flashTeal)
                    .frame(width: geo.size.width * (Double(currentStep + 1) / Double(totalSteps)), height: 4)
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step 1: Resume (required)
    private var step1_Resume: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "Upload Your Resume", subtitle: "Step 1 of \(totalSteps)")
                Text("Upload a PDF resume so JobHarvest can fill out applications on your behalf.")
                    .foregroundColor(.secondary)

                Button(action: { showDocumentPicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: resumeData != nil ? "doc.fill" : "doc.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(resumeData != nil ? .flashTeal : .flashTextSecondary)
                        Text(resumeData != nil ? resumeFileName : "Tap to select PDF")
                            .foregroundColor(resumeData != nil ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.flashTeal.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8])))
                }

                if resumeData == nil {
                    Text("A resume is required to continue.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Step 2: Name
    private var step2_Name: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "What's your name?", subtitle: "Step 2 of \(totalSteps)")
                TextField("First Name", text: $firstName)
                    .quizFieldStyle()
                TextField("Last Name", text: $lastName)
                    .quizFieldStyle()
            }
            .padding(24)
        }
    }

    // MARK: - Step 3: Contact
    private var step3_Contact: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "Contact Info", subtitle: "Step 3 of \(totalSteps)")
                TextField("Phone Number", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .quizFieldStyle()
            }
            .padding(24)
        }
    }

    // MARK: - Step 4: Work Authorization
    private var step4_WorkAuth: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "Work Authorization", subtitle: "Step 4 of \(totalSteps)")
                ForEach(workAuthOptions, id: \.self) { option in
                    Button(action: { workAuth = option }) {
                        HStack {
                            Text(option)
                            Spacer()
                            if workAuth == option {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.flashTeal)
                            }
                        }
                        .padding()
                        .background(workAuth == option ? Color.flashTeal.opacity(0.1) : Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(workAuth == option ? Color.flashTeal : Color.gray.opacity(0.3)))
                    }
                    .foregroundColor(.primary)
                }
                Picker("Requires Sponsorship", selection: $requiresSponsorship) {
                    Text("Yes").tag("Yes")
                    Text("No").tag("No")
                }
                .pickerStyle(.segmented)
                .padding(.top, 8)
            }
            .padding(24)
        }
    }

    // MARK: - Step 5: Job Preferences
    private var step5_Preferences: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "Job Preferences", subtitle: "Step 5 of \(totalSteps)")

                Text("Job Type").font(.headline)
                ForEach(["Internship", "Part-Time", "Full-Time", "Contract"], id: \.self) { type in
                    Button(action: {
                        if jobTypes.contains(type) {
                            jobTypes.removeAll { $0 == type }
                        } else {
                            jobTypes.append(type)
                        }
                    }) {
                        HStack {
                            Image(systemName: jobTypes.contains(type) ? "checkmark.square.fill" : "square")
                                .foregroundColor(jobTypes.contains(type) ? .flashTeal : .gray)
                            Text(type)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundColor(.primary)
                }

                Toggle("Remote Only", isOn: $remoteOnly).tint(.flashTeal)

                Divider().padding(.vertical, 8)

                Text("Skills").font(.headline)
                Text("Select skills relevant to your job search")
                    .font(.caption)
                    .foregroundColor(.secondary)

                FlowLayout(items: suggestedSkills) { skill in
                    Button(action: {
                        if skills.contains(skill) {
                            skills.removeAll { $0 == skill }
                        } else {
                            skills.append(skill)
                        }
                    }) {
                        Text(skill)
                            .font(.callout)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(skills.contains(skill) ? Color.flashTeal : Color.flashTeal.opacity(0.1))
                            .foregroundColor(skills.contains(skill) ? .white : .flashTeal)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }

                if let error = error {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Back") { currentStep -= 1 }
                    .secondaryButtonStyle()
            }

            if currentStep < totalSteps - 1 {
                Button("Next") { currentStep += 1 }
                    .primaryButtonStyle()
                    .disabled(!canAdvance)
            } else {
                Button(action: submitProfile) {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Get Started")
                    }
                }
                .primaryButtonStyle()
                .disabled(isSubmitting)
            }
        }
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 0: return resumeData != nil
        case 1: return !firstName.isEmpty && !lastName.isEmpty
        default: return true
        }
    }

    // MARK: - Submit
    private func submitProfile() {
        isSubmitting = true
        error = nil
        Task {
            do {
                // STEP 1: Merge quiz answers into the shared VM's profile FIRST
                // This must happen BEFORE uploadResume, because uploadResume POSTs
                // the full profileVM.profile to the backend.
                profileVM.profile.firstName = firstName
                profileVM.profile.lastName = lastName
                if !phone.isEmpty { profileVM.profile.phone = phone }
                profileVM.profile.workAuthorization = workAuth
                profileVM.profile.sponsorship = requiresSponsorship
                if !resumeFileName.isEmpty { profileVM.profile.resumeFileName = resumeFileName }
                profileVM.profile.jobPreferences = JobPreferences(
                    jobTypes: jobTypes.isEmpty ? nil : jobTypes,
                    remoteOnly: remoteOnly
                )
                if !skills.isEmpty { profileVM.profile.skills = skills }

                // STEP 2: Upload resume (which POSTs profileVM.profile including merged fields)
                if let data = resumeData, !resumeFileName.isEmpty {
                    await profileVM.uploadResume(data: data, fileName: resumeFileName)
                }

                // STEP 3: Save full profile (in case no resume, or to ensure all fields saved)
                try await profileVM.updateProfile(profileVM.profile)

                // STEP 4: Mark onboarding complete
                await authVM.markOnboardingComplete()
                PreferencesQuizView.clearSavedQuizState()
            } catch {
                self.error = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle).font(.caption).foregroundColor(.flashTeal).fontWeight(.semibold)
            Text(title).font(.system(size: 24, weight: .bold)).foregroundColor(.flashNavy)
        }
    }
}

// MARK: - Quiz Field Style
private extension View {
    func quizFieldStyle() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.25)))
    }
}

// MARK: - Document Picker
struct DocumentPickerView: UIViewControllerRepresentable {
    let allowedTypes: [UTType]
    let completion: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (URL) -> Void
        init(completion: @escaping (URL) -> Void) { self.completion = completion }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            completion(url)
        }
    }
}
