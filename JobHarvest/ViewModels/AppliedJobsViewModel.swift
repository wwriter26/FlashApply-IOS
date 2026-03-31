import Foundation
import Combine
import os

@MainActor
final class AppliedJobsViewModel: ObservableObject {
    nonisolated init() {}
    @Published var applying: [AppliedJob] = []
    @Published var applied: [AppliedJob] = []
    @Published var screen: [AppliedJob] = []
    @Published var interview: [AppliedJob] = []
    @Published var offer: [AppliedJob] = []
    @Published var archived: [AppliedJob] = []
    @Published var failed: [AppliedJob] = []
    @Published var selectedJob: AppliedJob?
    @Published var selectedJobLoading = false
    @Published var isLoading = false
    @Published var isLoaded = false
    @Published var error: String?
    @Published var showActiveOnly = true

    private let network = NetworkService.shared
    private var lastFetchedAt: Date?

    var activeStages: [PipelineStage] { PipelineStage.allCases.filter { $0.isActive } }
    var allStages: [PipelineStage] { PipelineStage.allCases }

    // MARK: - Fetch
    func fetchAppliedJobs() async {
        isLoading = true
        error = nil
        AppLogger.jobs.debug("fetchAppliedJobs: loading pipeline")
        do {
            let wrapper: APIResponse<AppliedJobsResponse> = try await network.request("/getAppliedJobs")
            let response = wrapper.data ?? AppliedJobsResponse()
            applyResponse(response)
            isLoaded = true
            lastFetchedAt = Date()
            let applying = response.applying?.count ?? 0
            let applied = response.applied?.count ?? 0
            let screen = response.screen?.count ?? 0
            let interview = response.interview?.count ?? 0
            let offer = response.offer?.count ?? 0

            let total: Int = applying + applied + screen + interview + offer
            AppLogger.jobs.info("fetchAppliedJobs: loaded \(total) active jobs across pipeline")
        } catch {
            AppLogger.jobs.error("fetchAppliedJobs: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }
        isLoading = false
    }

    func silentRefresh() async {
        do {
            let wrapper: APIResponse<AppliedJobsResponse> = try await network.request("/getAppliedJobs")
            let response = wrapper.data ?? AppliedJobsResponse()
            applyResponse(response)
            lastFetchedAt = Date()
        } catch {
            AppLogger.jobs.error("Silent refresh failed: \(error)")
        }
    }

    func refreshIfStale() async {
        guard let last = lastFetchedAt, Date().timeIntervalSince(last) > 60 else { return }
        await silentRefresh()
    }

    private func applyResponse(_ response: AppliedJobsResponse) {
        applying  = tag(response.applying ?? [],  stage: .applying)
        applied   = tag(response.applied ?? [],   stage: .applied)
        screen    = tag(response.screen ?? [],    stage: .screen)
        interview = tag(response.interview ?? [], stage: .interview)
        offer     = tag(response.offer ?? [],     stage: .offer)
        archived  = tag(response.archived ?? [],  stage: .archived)
        failed    = tag(response.failed ?? [],    stage: .failed)
    }

    private func tag(_ jobs: [AppliedJob], stage: PipelineStage) -> [AppliedJob] {
        jobs.map { var j = $0; j.stage = stage; return j }
    }

    // MARK: - Add card after swipe (optimistic)
    func addJobFromSwipe(_ job: AppliedJob) {
        var tagged = job
        tagged.stage = .applying
        applying.insert(tagged, at: 0)
    }

    // MARK: - Move Job
    func moveJob(_ job: AppliedJob, to newStage: PipelineStage) async {
        // Optimistic update
        removeFromAllStages(jobUrl: job.jobUrl)
        var moved = job
        moved.stage = newStage
        appendToStage(moved, stage: newStage)

        // Backend sync
        do {
            struct MoveBody: Encodable {
                let jobUrl: String
                let newStatus: String
            }
            let body = MoveBody(jobUrl: job.jobUrl, newStatus: newStage.backendKey)
            let _: MessageResponse = try await network.request("/moveJobStatus", method: "POST", body: body)
        } catch {
            AppLogger.jobs.error("Move job failed: \(error)")
            // Revert on failure
            await silentRefresh()
            self.error = "Could not update stage. Tap to retry."
        }
    }

    // MARK: - Fetch Job Details
    func fetchJobDetails(jobUrl: String, companyId: String?) async {
        selectedJobLoading = true
        defer { selectedJobLoading = false }
        do {
            struct DetailRequest: Encodable { let jobUrl: String; let companyId: String? }
            let req = DetailRequest(jobUrl: jobUrl, companyId: companyId)

            // /getJobDetails returns the detail object at the top level (no {"data":...} envelope).
            let detail: JobDetailResponse = try await network.request("/getJobDetails", method: "POST", body: req)

            // Capture the current selectedJob identity so a quick dismiss + reopen
            // of a different job cannot merge stale detail into the wrong entry.
            guard var job = selectedJob, job.jobUrl == jobUrl else {
                AppLogger.jobs.debug("fetchJobDetails: selectedJob changed mid-flight, discarding result for \(jobUrl)")
                return
            }
            job.jobDescription = detail.jobDescription
            job.jobDescriptionHTML = detail.jobDescriptionHTML
            job.desiredSkillsTags = detail.desiredSkillsTags
            job.jobRequirements = detail.jobRequirements
            job.jobResponsibilities = detail.jobResponsibilities
            job.companyData = detail.companyData
            selectedJob = job
        } catch {
            AppLogger.jobs.error("fetchJobDetails: \(error.localizedDescription)")
        }
    }

    // MARK: - Stage Accessors
    func jobs(for stage: PipelineStage) -> [AppliedJob] {
        switch stage {
        case .applying:  return applying
        case .applied:   return applied
        case .screen:    return screen
        case .interview: return interview
        case .offer:     return offer
        case .archived:  return archived
        case .failed:    return failed
        }
    }

    private func removeFromAllStages(jobUrl: String) {
        applying.removeAll  { $0.jobUrl == jobUrl }
        applied.removeAll   { $0.jobUrl == jobUrl }
        screen.removeAll    { $0.jobUrl == jobUrl }
        interview.removeAll { $0.jobUrl == jobUrl }
        offer.removeAll     { $0.jobUrl == jobUrl }
        archived.removeAll  { $0.jobUrl == jobUrl }
        failed.removeAll    { $0.jobUrl == jobUrl }
    }

    private func appendToStage(_ job: AppliedJob, stage: PipelineStage) {
        switch stage {
        case .applying:  applying.append(job)
        case .applied:   applied.append(job)
        case .screen:    screen.append(job)
        case .interview: interview.append(job)
        case .offer:     offer.append(job)
        case .archived:  archived.append(job)
        case .failed:    failed.append(job)
        }
    }

    // MARK: - Reset
    func reset() {
        applying = []
        applied = []
        screen = []
        interview = []
        offer = []
        archived = []
        failed = []
        selectedJob = nil
        selectedJobLoading = false
        isLoading = false
        isLoaded = false
        error = nil
        showActiveOnly = true
        lastFetchedAt = nil
    }
}
