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

    // Custom encode: exclude backend-managed fields.
    // Always send non-null values — empty strings / empty arrays instead of null
    // to prevent DynamoDB from storing null entries.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // String fields — nil becomes ""
        try container.encode(firstName ?? "", forKey: .firstName)
        try container.encode(lastName ?? "", forKey: .lastName)
        try container.encode(email ?? "", forKey: .email)
        try container.encode(phone ?? "", forKey: .phone)
        try container.encode(workAuthorization ?? "", forKey: .workAuthorization)
        try container.encode(sponsorship ?? "", forKey: .sponsorship)
        try container.encode(address ?? "", forKey: .address)
        try container.encode(street ?? "", forKey: .street)
        try container.encode(city ?? "", forKey: .city)
        try container.encode(state ?? "", forKey: .state)
        try container.encode(zipCode ?? "", forKey: .zipCode)
        try container.encode(country ?? "", forKey: .country)
        try container.encode(countryOfResidence ?? "", forKey: .countryOfResidence)
        try container.encode(additionalInformation ?? "", forKey: .additionalInformation)
        try container.encode(careerSummaryHeadline ?? "", forKey: .careerSummaryHeadline)
        try container.encode(yearsOfExperience ?? "", forKey: .yearsOfExperience)
        try container.encode(linkedIn ?? "", forKey: .linkedIn)
        try container.encode(github ?? "", forKey: .github)
        try container.encode(portfolio ?? "", forKey: .portfolio)
        try container.encode(website ?? "", forKey: .website)
        try container.encode(twitter ?? "", forKey: .twitter)
        try container.encode(resumeFileName ?? "", forKey: .resumeFileName)
        try container.encode(transcriptFileName ?? "", forKey: .transcriptFileName)
        try container.encode(availableStartDate ?? "", forKey: .availableStartDate)
        try container.encode(birthday ?? "", forKey: .birthday)
        try container.encode(authorizedToWorkInUS ?? "", forKey: .authorizedToWorkInUS)
        try container.encode(authorizedToWorkInUK ?? "", forKey: .authorizedToWorkInUK)
        try container.encode(authorizedToWorkInCA ?? "", forKey: .authorizedToWorkInCA)
        try container.encode(isUsCitizen ?? "", forKey: .isUsCitizen)
        try container.encode(pronouns ?? "", forKey: .pronouns)
        try container.encode(hasDriversLicenseAndVehicle ?? "", forKey: .hasDriversLicenseAndVehicle)
        try container.encode(willingToRelocate ?? "", forKey: .willingToRelocate)
        try container.encode(willingToCommute ?? "", forKey: .willingToCommute)
        try container.encode(willingToTravel ?? "", forKey: .willingToTravel)
        try container.encode(securityClearance ?? "", forKey: .securityClearance)
        try container.encode(disabilityStatus ?? "", forKey: .disabilityStatus)
        try container.encode(gender ?? "", forKey: .gender)
        try container.encode(veteranStatus ?? "", forKey: .veteranStatus)
        try container.encode(hispanicOrLatino ?? "", forKey: .hispanicOrLatino)
        try container.encode(isLgbtq ?? "", forKey: .isLgbtq)
        try container.encode(referralCode ?? "", forKey: .referralCode)
        try container.encode(plan ?? "", forKey: .plan)
        try container.encode(stripeCustomerId ?? "", forKey: .stripeCustomerId)

        // Array fields — nil becomes []
        try container.encode(workHistory ?? [], forKey: .workHistory)
        try container.encode(educationHistory ?? [], forKey: .educationHistory)
        try container.encode(skills ?? [], forKey: .skills)
        try container.encode(certifications ?? [], forKey: .certifications)
        try container.encode(experienceLevel ?? [], forKey: .experienceLevel)
        try container.encode(otherLinks ?? [], forKey: .otherLinks)
        try container.encode(preferredJobLocations ?? [], forKey: .preferredJobLocations)
        try container.encode(jobCategoryInterests ?? [], forKey: .jobCategoryInterests)
        try container.encode(lookingForInCompany ?? [], forKey: .lookingForInCompany)
        try container.encode(ethnicity ?? [], forKey: .ethnicity)
        try container.encode(toolsWorkedWith ?? [], forKey: .toolsWorkedWith)
        try container.encode(licenses ?? [], forKey: .licenses)

        // Numeric / special fields — encode only if set (these are truly optional)
        try container.encodeIfPresent(desiredSalary, forKey: .desiredSalary)
        try container.encodeIfPresent(jobPreferences, forKey: .jobPreferences)
        try container.encodeIfPresent(eeo, forKey: .eeo)

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
