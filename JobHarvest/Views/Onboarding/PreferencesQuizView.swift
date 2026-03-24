import SwiftUI
import UIKit
import UniformTypeIdentifiers
import os

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
    @State private var isParsing = false
    @State private var parseStatus = ""

    // New fields
    @State private var experienceLevel: [String] = []
    @State private var careerSummary = ""
    @State private var linkedInURL = ""
    @State private var githubURL = ""
    @State private var portfolioURL = ""
    @State private var websiteURL = ""
    @State private var desiredSalary = ""
    @State private var locationCity = ""
    @State private var locationState = ""
    @State private var willingToRelocate = "Yes"
    @State private var jobCategories: [String] = []

    private let totalSteps = 8
    private let workAuthOptions = ["US Citizen", "Green Card", "H-1B Visa", "OPT/CPT", "Other"]
    private let experienceLevelOptions = ["Internship", "Entry Level & New Grad", "Mid-Level", "Senior", "Lead / Principal", "Executive"]
    private let jobCategoryOptions = [
        "Software Development", "AI & Machine Learning", "Data Science",
        "Product Management", "Design / UX", "Marketing",
        "Sales", "Finance", "Operations",
        "Human Resources", "Customer Success", "Healthcare",
        "Education", "Legal", "Information Technology (IT)"
    ]
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
        static let experienceLevel = "quiz_experienceLevel"
        static let careerSummary = "quiz_careerSummary"
        static let linkedInURL = "quiz_linkedInURL"
        static let githubURL = "quiz_githubURL"
        static let portfolioURL = "quiz_portfolioURL"
        static let websiteURL = "quiz_websiteURL"
        static let desiredSalary = "quiz_desiredSalary"
        static let locationCity = "quiz_locationCity"
        static let locationState = "quiz_locationState"
        static let willingToRelocate = "quiz_willingToRelocate"
        static let jobCategories = "quiz_jobCategories"
    }

    static func clearSavedQuizState() {
        let defaults = UserDefaults.standard
        [QuizKeys.currentStep, QuizKeys.firstName, QuizKeys.lastName,
         QuizKeys.phone, QuizKeys.workAuth, QuizKeys.requiresSponsorship,
         QuizKeys.skills, QuizKeys.jobTypes, QuizKeys.remoteOnly,
         QuizKeys.resumeFileName, QuizKeys.experienceLevel, QuizKeys.careerSummary,
         QuizKeys.linkedInURL, QuizKeys.githubURL, QuizKeys.portfolioURL,
         QuizKeys.websiteURL, QuizKeys.desiredSalary, QuizKeys.locationCity,
         QuizKeys.locationState, QuizKeys.willingToRelocate, QuizKeys.jobCategories
        ].forEach { defaults.removeObject(forKey: $0) }
    }

    var body: some View {
        quizStackWithPersistence
    }

    // MARK: - Persistence chain (split to avoid type-checker timeout)

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

    private var quizStackWithPersistenceB: some View {
        quizStackWithPersistenceA
            .onChange(of: requiresSponsorship) { v in UserDefaults.standard.set(v, forKey: QuizKeys.requiresSponsorship) }
            .onChange(of: skills) { v in UserDefaults.standard.set(v, forKey: QuizKeys.skills) }
            .onChange(of: jobTypes) { v in UserDefaults.standard.set(v, forKey: QuizKeys.jobTypes) }
            .onChange(of: remoteOnly) { v in UserDefaults.standard.set(v, forKey: QuizKeys.remoteOnly) }
            .onChange(of: resumeFileName) { v in UserDefaults.standard.set(v, forKey: QuizKeys.resumeFileName) }
    }

    private var quizStackWithPersistenceC: some View {
        quizStackWithPersistenceB
            .onChange(of: experienceLevel) { v in UserDefaults.standard.set(v, forKey: QuizKeys.experienceLevel) }
            .onChange(of: careerSummary) { v in UserDefaults.standard.set(v, forKey: QuizKeys.careerSummary) }
            .onChange(of: linkedInURL) { v in UserDefaults.standard.set(v, forKey: QuizKeys.linkedInURL) }
            .onChange(of: githubURL) { v in UserDefaults.standard.set(v, forKey: QuizKeys.githubURL) }
            .onChange(of: portfolioURL) { v in UserDefaults.standard.set(v, forKey: QuizKeys.portfolioURL) }
    }

    private var quizStackWithPersistence: some View {
        quizStackWithPersistenceC
            .onChange(of: websiteURL) { v in UserDefaults.standard.set(v, forKey: QuizKeys.websiteURL) }
            .onChange(of: desiredSalary) { v in UserDefaults.standard.set(v, forKey: QuizKeys.desiredSalary) }
            .onChange(of: locationCity) { v in UserDefaults.standard.set(v, forKey: QuizKeys.locationCity) }
            .onChange(of: locationState) { v in UserDefaults.standard.set(v, forKey: QuizKeys.locationState) }
            .onChange(of: willingToRelocate) { v in UserDefaults.standard.set(v, forKey: QuizKeys.willingToRelocate) }
            .onChange(of: jobCategories) { v in UserDefaults.standard.set(v, forKey: QuizKeys.jobCategories) }
    }

    // MARK: - Main Quiz Layout

    private var quizStack: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                TabView(selection: $currentStep) {
                    step1_Resume.tag(0)
                    step2_Name.tag(1)
                    step3_Contact.tag(2)
                    step4_WorkAuth.tag(3)
                    step5_Experience.tag(4)
                    step6_Links.tag(5)
                    step7_LocationSalary.tag(6)
                    step8_Preferences.tag(7)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

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
                    Button("Skip") { showSkipConfirm = true }
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
                Text("The more you fill out, the better your job matches will be. You'll also need a resume before you can start swiping. You can complete your profile anytime from the Profile tab.")
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
        experienceLevel = defaults.stringArray(forKey: QuizKeys.experienceLevel) ?? []
        careerSummary = defaults.string(forKey: QuizKeys.careerSummary) ?? ""
        linkedInURL = defaults.string(forKey: QuizKeys.linkedInURL) ?? ""
        githubURL = defaults.string(forKey: QuizKeys.githubURL) ?? ""
        portfolioURL = defaults.string(forKey: QuizKeys.portfolioURL) ?? ""
        websiteURL = defaults.string(forKey: QuizKeys.websiteURL) ?? ""
        desiredSalary = defaults.string(forKey: QuizKeys.desiredSalary) ?? ""
        locationCity = defaults.string(forKey: QuizKeys.locationCity) ?? ""
        locationState = defaults.string(forKey: QuizKeys.locationState) ?? ""
        willingToRelocate = defaults.string(forKey: QuizKeys.willingToRelocate) ?? "Yes"
        jobCategories = defaults.stringArray(forKey: QuizKeys.jobCategories) ?? []
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

    // MARK: - Step 1: Resume

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
                    Text("A resume is required to start swiping on jobs.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if isParsing {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(parseStatus)
                            .font(.caption)
                            .foregroundColor(.flashTeal)
                    }
                    .padding(.top, 4)
                }

                if resumeData != nil && !isParsing {
                    Text("Resume uploaded! We'll use it to pre-fill your profile.")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(24)
        }
        .onChange(of: resumeData) { newData in
            guard let data = newData, !resumeFileName.isEmpty else { return }
            parseResumeAndPrefill(data: data, fileName: resumeFileName)
        }
    }

    private func parseResumeAndPrefill(data: Data, fileName: String) {
        isParsing = true
        parseStatus = "Uploading resume..."
        Task {
            // 1. Upload to S3
            await profileVM.uploadResume(data: data, fileName: fileName)

            // 2. Call /parseResume
            parseStatus = "Parsing your resume..."
            do {
                let identityId = try await AuthService.shared.getIdentityId()
                let body = ["identityId": identityId]
                let _: MessageResponse = try await NetworkService.shared.request("/parseResume", method: "POST", body: body)
                AppLogger.files.info("Quiz: parseResume success")
            } catch {
                AppLogger.files.error("Quiz: parseResume failed — \(error.localizedDescription)")
                isParsing = false
                parseStatus = ""
                return
            }

            // 3. Re-fetch profile to get parsed data
            parseStatus = "Loading parsed data..."
            await profileVM.fetchProfile()

            // 4. Pre-fill quiz fields from parsed profile
            let p = profileVM.profile
            if firstName.isEmpty { firstName = p.firstName ?? "" }
            if lastName.isEmpty { lastName = p.lastName ?? "" }
            if phone.isEmpty { phone = p.phone ?? "" }
            if let auth = p.authorizedToWorkInUS, !auth.isEmpty { workAuth = auth }
            if let sp = p.sponsorship, !sp.isEmpty { requiresSponsorship = sp }
            if skills.isEmpty { skills = p.skills ?? [] }
            if experienceLevel.isEmpty { experienceLevel = p.experienceLevel ?? [] }
            if careerSummary.isEmpty { careerSummary = p.careerSummaryHeadline ?? "" }
            if linkedInURL.isEmpty { linkedInURL = p.linkedIn ?? "" }
            if githubURL.isEmpty { githubURL = p.github ?? "" }
            if portfolioURL.isEmpty { portfolioURL = p.portfolio ?? "" }
            if websiteURL.isEmpty { websiteURL = p.website ?? "" }
            if locationCity.isEmpty { locationCity = p.city ?? "" }
            if locationState.isEmpty { locationState = p.state ?? "" }
            if let salary = p.desiredSalary, desiredSalary.isEmpty {
                desiredSalary = String(Int(salary))
            }
            if let relocate = p.willingToRelocate, !relocate.isEmpty {
                willingToRelocate = relocate
            }
            if jobCategories.isEmpty { jobCategories = p.jobCategoryInterests ?? [] }
            if let prefs = p.jobPreferences {
                if jobTypes.isEmpty { jobTypes = prefs.jobTypes ?? [] }
                if let remote = prefs.remoteOnly { remoteOnly = remote }
            }

            isParsing = false
            parseStatus = ""
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
                Text("Optional — but many applications require a phone number.")
                    .font(.caption).foregroundColor(.secondary)
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
                HStack {
                    Text("Requires Sponsorship")
                    Spacer()
                    Picker("", selection: $requiresSponsorship) {
                        Text("Yes").tag("Yes")
                        Text("No").tag("No")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
    }

    // MARK: - Step 5: Experience Level

    private var step5_Experience: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "Experience Level", subtitle: "Step 5 of \(totalSteps)")
                Text("Select all that apply — this helps match you with the right roles.")
                    .font(.caption).foregroundColor(.secondary)

                ForEach(experienceLevelOptions, id: \.self) { level in
                    Button(action: {
                        if experienceLevel.contains(level) {
                            experienceLevel.removeAll { $0 == level }
                        } else {
                            experienceLevel.append(level)
                        }
                    }) {
                        HStack {
                            Image(systemName: experienceLevel.contains(level) ? "checkmark.square.fill" : "square")
                                .foregroundColor(experienceLevel.contains(level) ? .flashTeal : .gray)
                            Text(level)
                            Spacer()
                        }
                        .padding()
                        .background(experienceLevel.contains(level) ? Color.flashTeal.opacity(0.1) : Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(experienceLevel.contains(level) ? Color.flashTeal : Color.gray.opacity(0.3)))
                    }
                    .foregroundColor(.primary)
                }

                Divider().padding(.vertical, 4)

                Text("Career Summary").font(.headline)
                Text("A short headline about your experience (optional)")
                    .font(.caption).foregroundColor(.secondary)
                TextField("e.g. Full-Stack Developer with 3 years experience", text: $careerSummary)
                    .quizFieldStyle()
            }
            .padding(24)
        }
    }

    // MARK: - Step 6: Links

    private var step6_Links: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "Your Links", subtitle: "Step 6 of \(totalSteps)")
                Text("Add any profiles or portfolios. All optional — but LinkedIn is used by most applications.")
                    .font(.caption).foregroundColor(.secondary)

                linkField(icon: "link", placeholder: "LinkedIn URL", text: $linkedInURL)
                linkField(icon: "chevron.left.forwardslash.chevron.right", placeholder: "GitHub URL", text: $githubURL)
                linkField(icon: "globe", placeholder: "Portfolio URL", text: $portfolioURL)
                linkField(icon: "safari", placeholder: "Website URL", text: $websiteURL)
            }
            .padding(24)
        }
    }

    private func linkField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.flashTeal)
                .frame(width: 24)
            TextField(placeholder, text: text)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .textContentType(.URL)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.25)))
    }

    // MARK: - Step 7: Location & Salary

    private var step7_LocationSalary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "Location & Salary", subtitle: "Step 7 of \(totalSteps)")

                Text("Where are you located?").font(.headline)
                HStack(spacing: 12) {
                    TextField("City", text: $locationCity).quizFieldStyle()
                    TextField("State", text: $locationState).quizFieldStyle()
                }

                HStack {
                    Text("Open to relocation?")
                    Spacer()
                    Picker("", selection: $willingToRelocate) {
                        Text("Yes").tag("Yes")
                        Text("No").tag("No")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }

                Divider().padding(.vertical, 4)

                Text("Desired Salary").font(.headline)
                Text("Annual salary in USD (optional)")
                    .font(.caption).foregroundColor(.secondary)
                HStack {
                    Text("$")
                        .foregroundColor(.secondary)
                    TextField("e.g. 75000", text: $desiredSalary)
                        .keyboardType(.numberPad)
                }
                .quizFieldStyle()
            }
            .padding(24)
        }
    }

    // MARK: - Step 8: Job Preferences (Skills, Types, Categories)

    private var step8_Preferences: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "Job Preferences", subtitle: "Step 8 of \(totalSteps)")

                Text("Job Type").font(.headline)
                ForEach(["Internship", "Part-Time", "Full-Time", "Contract"], id: \.self) { type in
                    Button(action: {
                        if jobTypes.contains(type) { jobTypes.removeAll { $0 == type } }
                        else { jobTypes.append(type) }
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

                Divider().padding(.vertical, 4)

                Text("Job Categories").font(.headline)
                Text("What fields interest you?")
                    .font(.caption).foregroundColor(.secondary)
                FlowLayout(items: jobCategoryOptions) { cat in
                    Button(action: {
                        if jobCategories.contains(cat) { jobCategories.removeAll { $0 == cat } }
                        else { jobCategories.append(cat) }
                    }) {
                        Text(cat)
                            .font(.callout)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(jobCategories.contains(cat) ? Color.flashTeal : Color.flashTeal.opacity(0.1))
                            .foregroundColor(jobCategories.contains(cat) ? .white : .flashTeal)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }

                Divider().padding(.vertical, 4)

                Text("Skills").font(.headline)
                Text("Select skills relevant to your job search")
                    .font(.caption).foregroundColor(.secondary)
                FlowLayout(items: suggestedSkills) { skill in
                    Button(action: {
                        if skills.contains(skill) { skills.removeAll { $0 == skill } }
                        else { skills.append(skill) }
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
                    .opacity(canAdvance ? 1.0 : 0.5)
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
        if isParsing { return false }
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
                // Merge quiz answers into profile
                profileVM.profile.firstName = firstName
                profileVM.profile.lastName = lastName
                if !phone.isEmpty { profileVM.profile.phone = phone }
                profileVM.profile.workAuthorization = workAuth
                profileVM.profile.sponsorship = requiresSponsorship
                if !resumeFileName.isEmpty { profileVM.profile.resumeFileName = resumeFileName }

                // Experience
                if !experienceLevel.isEmpty { profileVM.profile.experienceLevel = experienceLevel }
                if !careerSummary.isEmpty { profileVM.profile.careerSummaryHeadline = careerSummary }

                // Links
                if !linkedInURL.isEmpty { profileVM.profile.linkedIn = linkedInURL }
                if !githubURL.isEmpty { profileVM.profile.github = githubURL }
                if !portfolioURL.isEmpty { profileVM.profile.portfolio = portfolioURL }
                if !websiteURL.isEmpty { profileVM.profile.website = websiteURL }

                // Location & Salary
                if !locationCity.isEmpty { profileVM.profile.city = locationCity }
                if !locationState.isEmpty { profileVM.profile.state = locationState }
                profileVM.profile.willingToRelocate = willingToRelocate
                if let salary = Double(desiredSalary) { profileVM.profile.desiredSalary = salary }

                // Preferences
                profileVM.profile.jobPreferences = JobPreferences(
                    jobTypes: jobTypes.isEmpty ? nil : jobTypes,
                    remoteOnly: remoteOnly
                )
                if !skills.isEmpty { profileVM.profile.skills = skills }
                if !jobCategories.isEmpty { profileVM.profile.jobCategoryInterests = jobCategories }

                // Resume was already uploaded + parsed on step 1 via parseResumeAndPrefill.
                // Just save the final quiz answers (which may override parsed data).
                try await profileVM.updateProfile(profileVM.profile)

                // Mark onboarding complete
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
