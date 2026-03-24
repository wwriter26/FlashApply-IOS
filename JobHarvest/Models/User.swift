import Foundation

// MARK: - User / Auth
struct AuthUser: Identifiable {
    let id: String        // Cognito sub (userId)
    let username: String
    let email: String
    let emailVerified: Bool
    let isNewUser: Bool   // custom:firstLogin == "true"
}

// MARK: - API Response Wrapper
// Backend wraps all responses: {"message": "...", "data": {...}}
struct APIResponse<T: Codable>: Codable {
    let message: String?
    let data: T?
}

// MARK: - User Profile (matches /users/{userId}/profile response)
struct UserProfile: Codable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var workAuthorization: String?
    var sponsorship: String?

    // Address
    var address: String?
    var street: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var countryOfResidence: String?

    // Work / Education
    var workHistory: [WorkHistoryEntry]?
    var educationHistory: [EducationEntry]?
    var skills: [String]?
    var certifications: [CertificationEntry]?
    var additionalInformation: String?
    var careerSummaryHeadline: String?
    var experienceLevel: [String]?
    var yearsOfExperience: String?

    // Links
    var linkedIn: String?
    var github: String?
    var portfolio: String?
    var website: String?
    var twitter: String?
    var otherLinks: [String]?

    // Resume
    var resumeFileName: String?
    var transcriptFileName: String?
    var resumeLastUploaded: Double?

    // Job Preferences
    var jobPreferences: JobPreferences?
    var desiredSalary: Double?
    var availableStartDate: String?
    var birthday: String?
    var preferredJobLocations: [PreferredLocation]?
    var jobCategoryInterests: [String]?
    var lookingForInCompany: [String]?

    // Work authorization — per-country fields
    var authorizedToWorkInUS: String?
    var authorizedToWorkInUK: String?
    var authorizedToWorkInCA: String?
    var isUsCitizen: String?

    // Personal
    var pronouns: String?
    var hasDriversLicenseAndVehicle: String?
    var willingToRelocate: String?
    var willingToCommute: String?
    var willingToTravel: String?
    var securityClearance: String?

    // EEO
    var eeo: EEOData?
    var disabilityStatus: String?
    var gender: String?
    var ethnicity: [String]?
    var veteranStatus: String?
    var hispanicOrLatino: String?
    var isLgbtq: String?

    // Referral
    var referralCode: String?

    // Subscription
    var plan: String?
    var stripeCustomerId: String?
    var membershipPlanActive: Bool?

    // Misc
    var toolsWorkedWith: [String]?
    var licenses: [String]?
    var references: [AnyCodable]?

    // Backend-managed job tracking fields — decode only, NEVER send back.
    var acceptedJobs: AnyCodable?
    var appliedJobs: AnyCodable?

    // Map "education" property used by views to "educationHistory" from backend
    var education: [EducationEntry]? {
        get { educationHistory }
        set { educationHistory = newValue }
    }

    private enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, phone
        case workAuthorization = "authorizedToWork"
        case sponsorship = "requireSponsorship"
        case address, street
        case city = "homeCity"
        case state = "homeState"
        case zipCode = "zipcode"
        case country, countryOfResidence
        case workHistory = "jobHistory"
        case educationHistory, skills, certifications
        case additionalInformation, careerSummaryHeadline
        case experienceLevel, yearsOfExperience
        case linkedIn = "linkedin"
        case github, portfolio, website, twitter, otherLinks
        case resumeFileName = "resume"
        case transcriptFileName = "transcript"
        case resumeLastUploaded
        case jobPreferences, desiredSalary, availableStartDate, birthday
        case preferredJobLocations, jobCategoryInterests, lookingForInCompany
        case authorizedToWorkInUS, authorizedToWorkInUK, authorizedToWorkInCA
        case isUsCitizen
        case pronouns, hasDriversLicenseAndVehicle
        case willingToRelocate, willingToCommute, willingToTravel
        case securityClearance
        case eeo, disabilityStatus, gender
        case ethnicity = "race"
        case veteranStatus, hispanicOrLatino, isLgbtq
        case referralCode
        case plan = "membershipPlan"
        case stripeCustomerId, membershipPlanActive
        case toolsWorkedWith, licenses, references
        case acceptedJobs, appliedJobs
    }

    // Custom encode: exclude backend-managed fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(workAuthorization, forKey: .workAuthorization)
        try container.encodeIfPresent(sponsorship, forKey: .sponsorship)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(street, forKey: .street)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(zipCode, forKey: .zipCode)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encodeIfPresent(countryOfResidence, forKey: .countryOfResidence)
        try container.encodeIfPresent(workHistory, forKey: .workHistory)
        try container.encodeIfPresent(educationHistory, forKey: .educationHistory)
        try container.encodeIfPresent(skills, forKey: .skills)
        try container.encodeIfPresent(certifications, forKey: .certifications)
        try container.encodeIfPresent(additionalInformation, forKey: .additionalInformation)
        try container.encodeIfPresent(careerSummaryHeadline, forKey: .careerSummaryHeadline)
        try container.encodeIfPresent(experienceLevel, forKey: .experienceLevel)
        try container.encodeIfPresent(yearsOfExperience, forKey: .yearsOfExperience)
        try container.encodeIfPresent(linkedIn, forKey: .linkedIn)
        try container.encodeIfPresent(github, forKey: .github)
        try container.encodeIfPresent(portfolio, forKey: .portfolio)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(twitter, forKey: .twitter)
        try container.encodeIfPresent(otherLinks, forKey: .otherLinks)
        try container.encodeIfPresent(resumeFileName, forKey: .resumeFileName)
        try container.encodeIfPresent(transcriptFileName, forKey: .transcriptFileName)
        try container.encodeIfPresent(jobPreferences, forKey: .jobPreferences)
        try container.encodeIfPresent(desiredSalary, forKey: .desiredSalary)
        try container.encodeIfPresent(availableStartDate, forKey: .availableStartDate)
        try container.encodeIfPresent(birthday, forKey: .birthday)
        try container.encodeIfPresent(preferredJobLocations, forKey: .preferredJobLocations)
        try container.encodeIfPresent(jobCategoryInterests, forKey: .jobCategoryInterests)
        try container.encodeIfPresent(lookingForInCompany, forKey: .lookingForInCompany)
        try container.encodeIfPresent(authorizedToWorkInUS, forKey: .authorizedToWorkInUS)
        try container.encodeIfPresent(authorizedToWorkInUK, forKey: .authorizedToWorkInUK)
        try container.encodeIfPresent(authorizedToWorkInCA, forKey: .authorizedToWorkInCA)
        try container.encodeIfPresent(isUsCitizen, forKey: .isUsCitizen)
        try container.encodeIfPresent(pronouns, forKey: .pronouns)
        try container.encodeIfPresent(hasDriversLicenseAndVehicle, forKey: .hasDriversLicenseAndVehicle)
        try container.encodeIfPresent(willingToRelocate, forKey: .willingToRelocate)
        try container.encodeIfPresent(willingToCommute, forKey: .willingToCommute)
        try container.encodeIfPresent(willingToTravel, forKey: .willingToTravel)
        try container.encodeIfPresent(securityClearance, forKey: .securityClearance)
        try container.encodeIfPresent(eeo, forKey: .eeo)
        try container.encodeIfPresent(disabilityStatus, forKey: .disabilityStatus)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(ethnicity, forKey: .ethnicity)
        try container.encodeIfPresent(veteranStatus, forKey: .veteranStatus)
        try container.encodeIfPresent(hispanicOrLatino, forKey: .hispanicOrLatino)
        try container.encodeIfPresent(isLgbtq, forKey: .isLgbtq)
        try container.encodeIfPresent(referralCode, forKey: .referralCode)
        try container.encodeIfPresent(plan, forKey: .plan)
        try container.encodeIfPresent(stripeCustomerId, forKey: .stripeCustomerId)
        try container.encodeIfPresent(toolsWorkedWith, forKey: .toolsWorkedWith)
        try container.encodeIfPresent(licenses, forKey: .licenses)
        // acceptedJobs, appliedJobs, references, resumeLastUploaded, membershipPlanActive excluded
    }

    // MARK: - Profile completion (mirrors webapp logic)
    // Each entry: (label, isFilled). Matches the webapp's field counting approach.
    private var profileFields: [(String, Bool)] {
        [
            ("First Name",          !isFieldEmpty(firstName)),
            ("Last Name",           !isFieldEmpty(lastName)),
            ("Email",               !isFieldEmpty(email)),
            ("Phone",               !isFieldEmpty(phone)),
            ("Address",             !isFieldEmpty(address)),
            ("City",                !isFieldEmpty(city)),
            ("State",               !isFieldEmpty(state)),
            ("Zip Code",            !isFieldEmpty(zipCode)),
            ("Country of Residence",!isFieldEmpty(countryOfResidence)),
            ("Resume",              !isFieldEmpty(resumeFileName)),
            ("Transcript",          !isFieldEmpty(transcriptFileName)),
            ("LinkedIn",            !isFieldEmpty(linkedIn)),
            ("GitHub",              !isFieldEmpty(github)),
            ("Portfolio",           !isFieldEmpty(portfolio)),
            ("Website",             !isFieldEmpty(website)),
            ("Skills",              !(skills?.isEmpty ?? true)),
            ("Certifications",      !(certifications?.isEmpty ?? true)),
            ("Career Summary",      !isFieldEmpty(careerSummaryHeadline)),
            ("Experience Level",    !(experienceLevel?.isEmpty ?? true)),
            ("Additional Info",     !isFieldEmpty(additionalInformation)),
            ("Desired Salary",      desiredSalary != nil),
            ("Available Start Date",!isFieldEmpty(availableStartDate)),
            ("Birthday",            !isFieldEmpty(birthday)),
            ("Preferred Locations", !(preferredJobLocations?.isEmpty ?? true)),
            ("Job Categories",      !(jobCategoryInterests?.isEmpty ?? true)),
            ("Looking For",         !(lookingForInCompany?.isEmpty ?? true)),
            ("Authorized (US)",     !isFieldEmpty(authorizedToWorkInUS)),
            ("Authorized (CA)",     !isFieldEmpty(authorizedToWorkInCA)),
            ("US Citizen",          !isFieldEmpty(isUsCitizen)),
            ("Sponsorship",         !isFieldEmpty(sponsorship)),
            ("Security Clearance",  !isFieldEmpty(securityClearance)),
            ("Pronouns",            !isFieldEmpty(pronouns)),
            ("Driver's License",    !isFieldEmpty(hasDriversLicenseAndVehicle)),
            ("Relocate",            !isFieldEmpty(willingToRelocate)),
            ("Commute",             !isFieldEmpty(willingToCommute)),
            ("Gender",              !isFieldEmpty(gender)),
            ("Race / Ethnicity",    !(ethnicity?.isEmpty ?? true)),
            ("Veteran Status",      !isFieldEmpty(veteranStatus)),
            ("Disability Status",   !isFieldEmpty(disabilityStatus)),
            ("References",          !(references?.isEmpty ?? true)),
        ]
    }

    private func isFieldEmpty(_ value: String?) -> Bool {
        value == nil || value?.trimmingCharacters(in: .whitespaces).isEmpty == true
    }

    var missingFields: [String] {
        profileFields.filter { !$0.1 }.map { $0.0 }
    }

    var completionPercentage: Int {
        let total = profileFields.count
        let filled = profileFields.filter { $0.1 }.count
        guard total > 0 else { return 0 }
        return Int((Double(filled) / Double(total)) * 100)
    }
}

// Helper for arbitrary JSON (acceptedJobs, appliedJobs can be {} or [] or anything)
struct AnyCodable: Codable {
    init() {}
    init(from decoder: Decoder) throws {
        _ = try? decoder.singleValueContainer()
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

struct WorkHistoryEntry: Codable, Identifiable {
    var id: String { "\(company ?? "")\(title ?? "")\(startDate ?? "")" }
    var company: String?
    var title: String?
    var startDate: String?
    var endDate: String?
    var startDateYear: String?
    var startDateMonth: String?
    var endDateYear: String?
    var endDateMonth: String?
    var current: Bool?
    var description: String?
    var location: String?
    var industry: String?
    var accomplishments: [String]?

    private enum CodingKeys: String, CodingKey {
        case company = "companyName"
        case title = "jobTitle"
        case startDate, endDate
        case startDateYear, startDateMonth, endDateYear, endDateMonth
        case current = "currentlyWorking"
        case description, location, industry, accomplishments
    }
}

struct EducationEntry: Codable, Identifiable {
    var id: String { "\(institution ?? "")\(degree ?? "")" }
    var institution: String?
    var degree: String?
    var field: String?
    var startDate: String?
    var endDate: String?
    var startDateYear: String?
    var startDateMonth: String?
    var endDateYear: String?
    var endDateMonth: String?
    var current: Bool?
    var gpa: String?
    var accomplishments: [String]?
    var transcript: String?
    var transcriptUrl: String?

    private enum CodingKeys: String, CodingKey {
        case institution, degree
        case field = "fieldOfStudy"
        case startDate, endDate
        case startDateYear, startDateMonth, endDateYear, endDateMonth
        case current, gpa, accomplishments, transcript, transcriptUrl
    }
}

struct CertificationEntry: Codable, Identifiable {
    var id: String { name ?? UUID().uuidString }
    var name: String?
    var issuer: String?
    var date: String?
    var url: String?
}

struct JobPreferences: Codable {
    var jobTypes: [String]?
    var industries: [String]?
    var locations: [PreferredLocation]?
    var salaryMin: Double?
    var remoteOnly: Bool?
    var openToRelocation: Bool?
}

struct PreferredLocation: Codable, Identifiable {
    var id: String { "\(city ?? "")\(state ?? "")\(country ?? "")" }
    var city: String?
    var state: String?
    var country: String?
    var isRemote: Bool?
}

struct EEOData: Codable {
    var gender: String?
    var ethnicity: String?
    var veteranStatus: String?
    var disabilityStatus: String?
}
