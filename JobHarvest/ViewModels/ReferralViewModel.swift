import Foundation
import Combine
import os

@MainActor
final class ReferralViewModel: ObservableObject {
    nonisolated init() {}
    @Published var referralData: ReferralData?
    @Published var isLoading = false
    @Published var isLoaded = false
    @Published var error: String?
    @Published var payoutSuccess = false

    private let network = NetworkService.shared

    // MARK: - Fetch
    func fetchReferralData() async {
        isLoading = true
        error = nil
        AppLogger.referral.debug("fetchReferralData: loading")
        do {
            let wrapper: APIResponse<ReferralData> = try await network.request("/getReferral")
            let response = wrapper.data
            referralData = response
            isLoaded = true
            AppLogger.referral.info("fetchReferralData: success — code = \(response?.referralCode ?? "nil")")
        } catch {
            AppLogger.referral.error("fetchReferralData: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }
        isLoading = false
    }

    // MARK: - Request Payout
    func requestPayout(method: String, details: [String: String]) async {
        isLoading = true
        error = nil
        AppLogger.referral.debug("requestPayout: method = \(method)")
        do {
            let body = PayoutRequest(payoutMethod: method, payload: details)
            let _: MessageResponse = try await network.request("/requestPayout", method: "POST", body: body)
            payoutSuccess = true
            AppLogger.referral.info("requestPayout: success via \(method)")
        } catch {
            AppLogger.referral.error("requestPayout: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }
        isLoading = false
    }

    var referralLink: String {
        guard let code = referralData?.referralCode else { return "https://jobharvest.com" }
        return "https://jobharvest.com?ref=\(code)"
    }

    var hasBalance: Bool {
        (referralData?.pendingPayout ?? 0) > 0
    }
}
