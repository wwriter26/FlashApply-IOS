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

    // Address — backend sends flat "address" string, but we also support structured fields
    var address: String?
    var street: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var countryOfResidence: String?

    // Work / Education — backend uses "educationHistory" not "education"
    var workHistory: [WorkHistoryEntry]?
    var educationHistory: [EducationEntry]?
    var skills: [String]?
    var certifications: [CertificationEntry]?
    var additionalInformation: String?
    var careerSummaryHeadline: String?

    // Links
    var linkedIn: String?
    var github: String?
    var portfolio: String?
    var otherLinks: [String]?

    // Resume
    var resumeFileName: String?
    var transcriptFileName: String?

    // Job Preferences — backend sends individual fields, not a nested object
    var jobPreferences: JobPreferences?
    var desiredSalary: Double?
    var availableStartDate: String?
    var birthday: String?

    // Work authorization — backend sends per-country fields
    var authorizedToWorkInUS: String?
    var authorizedToWorkInUK: String?
    var authorizedToWorkInCA: String?

    // EEO
    var eeo: EEOData?
    var disabilityStatus: String?
    var gender: String?
    var ethnicity: [String]?
    var veteranStatus: String?

    // Referral
    var referralCode: String?

    // Subscription
    var plan: String?
    var stripeCustomerId: String?

    // Backend-managed job tracking fields — decode only, NEVER send back.
    // These are DynamoDB String Sets managed by moveJob/acceptJob/rejectJob.
    // Sending null via profile update converts them from SS to NULL type,
    // which breaks moveJob's ADD/DELETE Set operations.
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
        case linkedIn = "linkedin"
        case github, portfolio, otherLinks
        case resumeFileName = "resume"
        case transcriptFileName = "transcript"
        case jobPreferences, desiredSalary, availableStartDate, birthday
        case authorizedToWorkInUS, authorizedToWorkInUK, authorizedToWorkInCA
        case eeo, disabilityStatus, gender
        case ethnicity = "race"
        case veteranStatus
        case referralCode
        case plan = "membershipPlan"
        case stripeCustomerId
        case acceptedJobs, appliedJobs
    }

    // Custom encode: exclude job-tracking fields that the backend manages
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
        try container.encodeIfPresent(workHistory, forKey: .workHistory)  // encodes as "jobHistory"
        try container.encodeIfPresent(educationHistory, forKey: .educationHistory)
        try container.encodeIfPresent(skills, forKey: .skills)
        try container.encodeIfPresent(certifications, forKey: .certifications)
        try container.encodeIfPresent(additionalInformation, forKey: .additionalInformation)
        try container.encodeIfPresent(careerSummaryHeadline, forKey: .careerSummaryHeadline)
        try container.encodeIfPresent(linkedIn, forKey: .linkedIn)
        try container.encodeIfPresent(github, forKey: .github)
        try container.encodeIfPresent(portfolio, forKey: .portfolio)
        try container.encodeIfPresent(otherLinks, forKey: .otherLinks)
        try container.encodeIfPresent(resumeFileName, forKey: .resumeFileName)
        try container.encodeIfPresent(transcriptFileName, forKey: .transcriptFileName)
        try container.encodeIfPresent(jobPreferences, forKey: .jobPreferences)
        try container.encodeIfPresent(desiredSalary, forKey: .desiredSalary)
        try container.encodeIfPresent(availableStartDate, forKey: .availableStartDate)
        try container.encodeIfPresent(birthday, forKey: .birthday)
        try container.encodeIfPresent(authorizedToWorkInUS, forKey: .authorizedToWorkInUS)
        try container.encodeIfPresent(authorizedToWorkInUK, forKey: .authorizedToWorkInUK)
        try container.encodeIfPresent(authorizedToWorkInCA, forKey: .authorizedToWorkInCA)
        try container.encodeIfPresent(eeo, forKey: .eeo)
        try container.encodeIfPresent(disabilityStatus, forKey: .disabilityStatus)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(ethnicity, forKey: .ethnicity)
        try container.encodeIfPresent(veteranStatus, forKey: .veteranStatus)
        try container.encodeIfPresent(referralCode, forKey: .referralCode)
        try container.encodeIfPresent(plan, forKey: .plan)
        try container.encodeIfPresent(stripeCustomerId, forKey: .stripeCustomerId)
        // acceptedJobs and appliedJobs intentionally excluded — backend-managed DynamoDB Sets
    }

    var completionPercentage: Int {
        var score = 0
        let total = 10
        if firstName != nil && lastName != nil { score += 1 }
        if email != nil { score += 1 }
        if phone != nil { score += 1 }
        if workAuthorization != nil || authorizedToWorkInUS != nil { score += 1 }
        if resumeFileName != nil { score += 1 }
        if !(skills?.isEmpty ?? true) { score += 1 }
        if !(workHistory?.isEmpty ?? true) { score += 1 }
        if !(educationHistory?.isEmpty ?? true) { score += 1 }
        if jobPreferences != nil { score += 1 }
        if city != nil || address != nil { score += 1 }
        return Int((Double(score) / Double(total)) * 100)
    }
}

// Helper for arbitrary JSON (acceptedJobs, appliedJobs can be {} or [] or anything)
struct AnyCodable: Codable {
    init() {}
    init(from decoder: Decoder) throws {
        // Accept any JSON value without crashing
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
    var jobTypes: [String]?       // "Full-time", "Part-time", "Contract", "Remote"
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
}

struct EEOData: Codable {
    var gender: String?
    var ethnicity: String?
    var veteranStatus: String?
    var disabilityStatus: String?
}
