import Foundation

// MARK: - Pipeline Stage
enum PipelineStage: String, Codable, CaseIterable {
    case applying  = "applying"
    case applied   = "applied"
    case screen    = "screen"
    case interview = "interview"
    case offer     = "offer"
    case archived  = "archived"
    case failed    = "failed"

    // Maps to backend request values for moveJobStatus
    var backendKey: String {
        switch self {
        case .applying:  return "applyingJobs"
        case .applied:   return "appliedJobs"
        case .screen:    return "screenJobs"
        case .interview: return "interviewJobs"
        case .offer:     return "offerJobs"
        case .archived:  return "archivedJobs"
        case .failed:    return "failedJobs"
        }
    }

    var isActive: Bool {
        switch self {
        case .archived, .failed: return false
        default: return true
        }
    }
}

// MARK: - Applied Job (list view)
struct AppliedJob: Codable, Identifiable {
    var id: String { jobUrl }

    let jobUrl: String
    let companyName: String?
    let jobTitle: String?
    let jobLocation: String?
    let payEstimate: PayEstimate?
    let jobCategories: [String]?
    let jobType: String?
    let companyId: String?
    var stage: PipelineStage?

    // Detailed fields (fetched on demand)
    var jobDescription: String?
    var jobDescriptionHTML: String?
    var desiredSkillsTags: [String]?
    var jobRequirements: [String]?
    var jobResponsibilities: [String]?
    var companyData: CompanyData?
}

// MARK: - Applied Jobs Response (GET /getAppliedJobs)
struct AppliedJobsResponse: Codable {
    let applying: [AppliedJob]?
    let applied: [AppliedJob]?
    let screen: [AppliedJob]?
    let interview: [AppliedJob]?
    let offer: [AppliedJob]?
    let archived: [AppliedJob]?
    let failed: [AppliedJob]?
}

// MARK: - Job Detail Response (GET /getJobDetails)
struct JobDetailResponse: Codable {
    let jobTitle: String?
    let companyName: String?
    let jobLocation: String?
    let jobDescription: String?
    let jobDescriptionHTML: String?
    let desiredSkillsTags: [String]?
    let jobCategories: [String]?
    let jobRequirements: [String]?
    let jobResponsibilities: [String]?
    let companyData: CompanyData?
}
