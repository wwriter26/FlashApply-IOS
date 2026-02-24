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
            var body: [String: Any] = [:]
            if let industry = filters.jobIndustry { body["jobIndustry"] = industry }
            if let state = filters.locationState { body["location"] = ["state": state] }
            if let types = filters.jobType { body["jobType"] = types }
            if let minSal = filters.minimumSalary { body["minimumSalary"] = minSal }
            if let posted = filters.postedAfterTimestamp { body["postedAfterTimestamp"] = posted }
            if let company = filters.companyKey { body["companyKey"] = company }
            if !seenUrls.isEmpty { body["exclude"] = Array(seenUrls) }

            let bodyData = try JSONSerialization.data(withJSONObject: body)

            struct GenericBody: Encodable {
                let data: Data
                func encode(to encoder: Encoder) throws { /* passthrough */ }
            }

            let response: FetchJobsResponse = try await network.request(
                "/users/\(try await AuthService.shared.getCurrentUserId())/jobs",
                method: "POST",
                body: RawBody(data: bodyData)
            )

            let newJobs = response.resolvedJobs
            newJobs.forEach { seenUrls.insert($0.jobUrl) }

            if appending {
                jobs.append(contentsOf: newJobs)
            } else {
                jobs = newJobs
            }
            isLoaded = true
        } catch let netErr as NetworkError where netErr.errorDescription?.contains("403") == true || netErr.errorDescription?.contains("No swipes") == true {
            noSwipesLeft = true
            isLoaded = true
        } catch {
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
            let userId = try await AuthService.shared.getCurrentUserId()
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

// MARK: - Helpers
private struct SwipeRequestBody: Encodable {
    let jobUrl: String
    let isAccepting: Bool
    let manualUserAnswers: [String: String]?
}

struct RawBody: Encodable {
    let data: Data
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(data: data, encoding: .utf8) ?? "{}")
    }
}
