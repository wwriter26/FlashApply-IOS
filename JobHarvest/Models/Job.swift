import Foundation

// MARK: - Job Card (swipe deck)
struct Job: Codable, Identifiable {
    var id: String { jobUrl }

    let jobUrl: String
    let jobTitle: String?
    let companyName: String?
    let jobLocation: String?
    let jobPosted: String?
    let jobType: String?
    let jobCategories: [String]?
    let jobDescription: String?
    let jobDescriptionHTML: String?
    let jobRequirements: [String]?
    let jobResponsibilities: [String]?
    let desiredSkillsTags: [String]?
    let payEstimate: PayEstimate?
    let companyId: String?
    let companyRating: String?
    let employeeCount: String?
    let companyData: CompanyData?
    let locationData: [LocationData]?
    let remoteHybridorOnsite: String?
    let manualInputFields: [ManualInputField]?
    let profitableMatch: Bool?
    let greatMatch: Bool?
    let isHighPaying: Bool?
    let isGreatFit: Bool?
}

struct PayEstimate: Codable {
    let salaryMin: Double?
    let salaryMax: Double?
    let currency: String?
    let salaryPeriod: String?
    let salaryType: String?

    enum CodingKeys: String, CodingKey {
        case salaryMin, salaryMax, currency
        case salaryPeriod = "period"
        case salaryType
    }
}

struct CompanyData: Codable {
    let name: String?
    let description: String?
    let size: String?
    let benefits: [String]?
    let tagline: String?
    let logoDomain: String?
    let website: String?
    let rating: String?
    let tags: [String]?
    let headquarters: String?
    let founded: String?
    let revenue: String?
    let type: String?
}

struct LocationData: Codable {
    let isRemote: Bool?
    let city: String?
    let state: String?
    let country: String?
}

struct ManualInputField: Codable, Identifiable {
    var id: String { fieldKey ?? classification ?? label ?? UUID().uuidString }
    let fieldKey: String?
    let fieldLabel: String?
    let fieldType: String?
    let label: String?
    let classification: String?
    let selectOptions: [String]?
    let options: [String]?
    let value: String?
    let required: Bool?
}

// MARK: - Job Filters
struct JobFilters: Codable {
    var jobIndustry: String?
    var locationState: String?
    var jobType: [String]?
    var minimumSalary: Double?
    var postedAfterTimestamp: String?
    var companyKey: String?
    var fromDB: Bool?
}

// MARK: - Fetch Jobs Response
struct FetchJobsResponse: Codable {
    let newJobs: [Job]?
    let jobs: [Job]?     // fallback key some endpoints use

    var resolvedJobs: [Job] { newJobs ?? jobs ?? [] }
}

// MARK: - Handle Swipe Response
struct SwipeResponse: Codable {
    let success: Bool?
    let message: String?
    let swipesRemaining: Int?
    let jobData: AppliedJob?
}
