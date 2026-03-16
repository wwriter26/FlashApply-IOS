import Foundation
import Combine
import os

@MainActor
final class JobCardsViewModel: ObservableObject {
    nonisolated init() {}
    @Published var jobs: [Job] = []
    @Published var isLoading = false
    @Published var isPrefetching = false
    @Published var isLoaded = false
    @Published var error: String?
    @Published var swipesRemaining: Int?
    @Published var noSwipesLeft = false

    private let network = NetworkService.shared
    private var seenUrls: Set<String> = []

    // MARK: - Fetch Job Cards
    func fetchJobs(filters: JobFilters = JobFilters(), appending: Bool = false) async {
        guard !isLoading else { return }
        isLoading = !appending
        isPrefetching = appending
        error = nil

        do {
            var params: [String: String] = [:]
            if let jobIndustry = filters.jobIndustry { params["jobIndustry"] = jobIndustry }
            if let locationState = filters.locationState { params["locationState"] = locationState }
            if let jobType = filters.jobType, !jobType.isEmpty { params["jobType"] = jobType.joined(separator: ",") }
            if let minimumSalary = filters.minimumSalary { params["minimumSalary"] = String(minimumSalary) }
            if let postedAfterTimestamp = filters.postedAfterTimestamp { params["postedAfterTimestamp"] = postedAfterTimestamp }
            if let companyKey = filters.companyKey { params["companyId"] = companyKey }
            if let fromDB = filters.fromDB { params["fromDB"] = fromDB ? "true" : "false" }
            if !seenUrls.isEmpty { params["exclude"] = seenUrls.joined(separator: ",") }

            let response: FetchJobsResponse = try await network.requestWithParams(
                "/users/\(try await AuthService.shared.getCurrentUserId())/jobs",
                params: params
            )

            let newJobs = response.resolvedJobs
            newJobs.forEach { seenUrls.insert($0.jobUrl) }

            if appending {
                jobs.append(contentsOf: newJobs)
            } else {
                jobs = newJobs
            }
            isLoaded = true
            AppLogger.jobs.info("fetchJobs: received \(newJobs.count) jobs (appending: \(appending), total deck: \(self.jobs.count))")
        } catch NetworkError.serverError(403, _) {
            AppLogger.jobs.info("fetchJobs: no swipes remaining (403)")
            noSwipesLeft = true
            isLoaded = true
        } catch {
            AppLogger.jobs.error("fetchJobs: failed — \(error.localizedDescription)")
            self.error = error.localizedDescription
        }

        isLoading = false
        isPrefetching = false
    }

    // MARK: - Handle Swipe
    func handleSwipe(job: Job, isAccepting: Bool, answers: [String: String] = [:]) async -> SwipeResponse? {
        // Remove card from deck immediately (optimistic)
        jobs.removeAll { $0.jobUrl == job.jobUrl }

        // Prefetch if deck running low
        if jobs.count <= 2 && !isPrefetching {
            Task { await fetchJobs(appending: true) }
        }

        do {
            let body = SwipeRequestBody(
                jobUrl: job.jobUrl,
                isAccepting: isAccepting,
                manualUserAnswers: answers.isEmpty ? nil : answers
            )
            let response: SwipeResponse = try await network.request(
                "/handleSwipe",
                method: "POST",
                body: body
            )
            if let remaining = response.swipesRemaining {
                swipesRemaining = remaining
            }
            return response
        } catch {
            AppLogger.jobs.error("Swipe error: \(error)")
            return nil
        }
    }

    var isEffectivelyLoading: Bool {
        (isLoading || isPrefetching) && jobs.isEmpty
    }
}

// MARK: - Request Bodies
private struct SwipeRequestBody: Encodable {
    let jobUrl: String
    let isAccepting: Bool
    let manualUserAnswers: [String: String]?
}

