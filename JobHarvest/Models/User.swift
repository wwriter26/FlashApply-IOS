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
    var sponsorship: Bool?

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
    var ethnicity: String?
    var veteranStatus: String?

    // Referral
    var referralCode: String?

    // Subscription
    var plan: String?
    var stripeCustomerId: String?

    // Backend-specific fields we need to accept but may not display
    var acceptedJobs: AnyCodable?
    var appliedJobs: AnyCodable?

    // Map "education" property used by views to "educationHistory" from backend
    var education: [EducationEntry]? {
        get { educationHistory }
        set { educationHistory = newValue }
    }

    private enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, phone, workAuthorization, sponsorship
        case address, street, city, state, zipCode, country, countryOfResidence
        case workHistory, educationHistory, skills, certifications
        case additionalInformation, careerSummaryHeadline
        case linkedIn, github, portfolio, otherLinks
        case resumeFileName, transcriptFileName
        case jobPreferences, desiredSalary, availableStartDate, birthday
        case authorizedToWorkInUS, authorizedToWorkInUK, authorizedToWorkInCA
        case eeo, disabilityStatus, gender, ethnicity, veteranStatus
        case referralCode, plan, stripeCustomerId
        case acceptedJobs, appliedJobs
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
    var current: Bool?
    var description: String?
    var location: String?
}

struct EducationEntry: Codable, Identifiable {
    var id: String { "\(institution ?? "")\(degree ?? "")" }
    var institution: String?
    var degree: String?
    var field: String?
    var startDate: String?
    var endDate: String?
    var current: Bool?
    var gpa: String?
    var accomplishments: [String]?
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
