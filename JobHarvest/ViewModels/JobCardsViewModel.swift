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
    @Published var swipesLeftToday: Int?
    @Published var enduringSwipes: Int?
    @Published var noSwipesLeft = false

    /// True after the first swipe response — means we have real counts from the backend
    var hasSwipeCounts: Bool { swipesLeftToday != nil }

    /// Total swipes available (daily + enduring)
    var totalSwipesLeft: Int? {
        guard let daily = swipesLeftToday else { return nil }
        return daily + (enduringSwipes ?? 0)
    }

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

            // Use JobsAPIResponse to capture swipe counts if backend sends them alongside jobs
            let response: JobsAPIResponse = try await network.requestWithParams(
                "/users/\(try await AuthService.shared.getCurrentUserId())/jobs",
                params: params
            )

            let newJobs = response.data ?? []
            newJobs.forEach { seenUrls.insert($0.jobUrl) }

            if appending {
                jobs.append(contentsOf: newJobs)
            } else {
                jobs = newJobs
            }

            // Capture swipe counts if the jobs endpoint returns them
            if let daily = response.swipesLeftToday {
                swipesLeftToday = daily
            }
            if let enduring = response.enduringSwipes {
                enduringSwipes = enduring
            }

            isLoaded = true
            AppLogger.jobs.info("fetchJobs: received \(newJobs.count) jobs (appending: \(appending), total deck: \(self.jobs.count))")
        } catch NetworkError.serverError(403, _) {
            AppLogger.jobs.info("fetchJobs: no swipes remaining (403)")
            isLoading = false
            isPrefetching = false
            swipesLeftToday = 0
            enduringSwipes = 0
            noSwipesLeft = true
            isLoaded = true
            return
        } catch {
            AppLogger.jobs.error("fetchJobs: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }

        isLoading = false
        isPrefetching = false
    }

    // MARK: - Fetch Swipe Status
    /// Fetches current swipe counts by making a lightweight swipe-check call.
    /// Called on initial load to populate the badge before any swipe happens.
    func fetchSwipeStatus() async {
        guard !hasSwipeCounts else { return } // already have real data
        do {
            let userId = try await AuthService.shared.getCurrentUserId()
            // Use the profile endpoint to check membership — swipe counts aren't
            // available from a dedicated endpoint, so we parse what we can
            let identityId = try await AuthService.shared.getIdentityId()

            // Make a reject swipe with an empty/invalid URL to get swipe counts back
            // without actually applying to a job. If the backend rejects it, we still
            // get swipe counts from the error or from a 403.
            // Instead, let's just accept we don't have counts until first swipe
            // and show a clear "–" indicator.
            AppLogger.jobs.debug("fetchSwipeStatus: no dedicated endpoint — counts shown after first swipe")
        } catch {
            AppLogger.jobs.error("fetchSwipeStatus: \(error)")
        }
    }

    // MARK: - Handle Swipe
    func handleSwipe(job: Job, isAccepting: Bool, answers: [String: String] = [:]) async -> SwipeResponse? {
        // Block if we know there are no swipes left
        if noSwipesLeft { return nil }
        if let total = totalSwipesLeft, total <= 0 {
            noSwipesLeft = true
            return nil
        }

        // Remove card from deck immediately (optimistic)
        jobs.removeAll { $0.jobUrl == job.jobUrl }

        // Prefetch if deck running low
        if jobs.count <= 2 && !isPrefetching {
            Task { await fetchJobs(appending: true) }
        }

        do {
            // identityId is required by the backend alongside jobUrl and isAccepting
            let identityId = try await AuthService.shared.getIdentityId()
            let body = SwipeRequestBody(
                jobUrl: job.jobUrl,
                isAccepting: isAccepting,
                identityId: identityId,
                manualUserAnswers: answers.isEmpty ? nil : answers
            )
            let wrapper: APIResponse<SwipeResponse> = try await network.request(
                "/handleSwipe",
                method: "POST",
                body: body
            )
            let response = wrapper.data

            // Update swipe counts from backend response
            if let daily = response?.swipesLeftToday {
                swipesLeftToday = daily
            }
            if let enduring = response?.enduringSwipes {
                enduringSwipes = enduring
            }

            // Check if out of swipes after this action
            if let daily = swipesLeftToday, let enduring = enduringSwipes,
               daily <= 0 && enduring <= 0 {
                noSwipesLeft = true
            }

            return response
        } catch NetworkError.serverError(403, _) {
            AppLogger.jobs.error("Swipe error: no swipes remaining (403)")
            swipesLeftToday = 0
            enduringSwipes = 0
            noSwipesLeft = true
            return nil
        } catch {
            AppLogger.jobs.error("Swipe error: \(error)")
            return nil
        }
    }

    var isEffectivelyLoading: Bool {
        (isLoading || isPrefetching) && jobs.isEmpty
    }

    // MARK: - Reset
    func reset() {
        jobs = []
        isLoading = false
        isPrefetching = false
        isLoaded = false
        error = nil
        swipesLeftToday = nil
        enduringSwipes = nil
        noSwipesLeft = false
        seenUrls = []
    }
}

// MARK: - Request Bodies
private struct SwipeRequestBody: Encodable {
    let jobUrl: String
    let isAccepting: Bool
    let identityId: String
    let manualUserAnswers: [String: String]?
}

