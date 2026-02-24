import Foundation

// MARK: - User / Auth
struct AuthUser: Identifiable {
    let id: String        // Cognito sub (userId)
    let username: String
    let email: String
    let emailVerified: Bool
    let isNewUser: Bool   // custom:firstLogin == "true"
}

// MARK: - User Profile (matches /users/{userId}/profile response)
struct UserProfile: Codable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var workAuthorization: String?
    var sponsorship: Bool?

    // Address
    var street: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?

    // Work / Education
    var workHistory: [WorkHistoryEntry]?
    var education: [EducationEntry]?
    var skills: [String]?
    var certifications: [CertificationEntry]?

    // Links
    var linkedIn: String?
    var github: String?
    var portfolio: String?
    var otherLinks: [String]?

    // Resume
    var resumeFileName: String?
    var transcriptFileName: String?

    // Job Preferences
    var jobPreferences: JobPreferences?

    // EEO
    var eeo: EEOData?

    // Referral
    var referralCode: String?

    // Subscription
    var plan: String?
    var stripeCustomerId: String?

    var completionPercentage: Int {
        var score = 0
        let total = 10
        if firstName != nil && lastName != nil { score += 1 }
        if email != nil { score += 1 }
        if phone != nil { score += 1 }
        if workAuthorization != nil { score += 1 }
        if resumeFileName != nil { score += 1 }
        if !(skills?.isEmpty ?? true) { score += 1 }
        if !(workHistory?.isEmpty ?? true) { score += 1 }
        if !(education?.isEmpty ?? true) { score += 1 }
        if jobPreferences != nil { score += 1 }
        if city != nil { score += 1 }
        return Int((Double(score) / Double(total)) * 100)
    }
}

struct WorkHistoryEntry: Codable, Identifiable {
    var id: String { "\(company)\(title)\(startDate ?? "")" }
    var company: String
    var title: String
    var startDate: String?
    var endDate: String?
    var current: Bool?
    var description: String?
    var location: String?
}

struct EducationEntry: Codable, Identifiable {
    var id: String { "\(institution)\(degree ?? "")" }
    var institution: String
    var degree: String?
    var field: String?
    var startDate: String?
    var endDate: String?
    var current: Bool?
    var gpa: String?
}

struct CertificationEntry: Codable, Identifiable {
    var id: String { name }
    var name: String
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
