import Foundation
import Combine

@MainActor
final class ReferralViewModel: ObservableObject {
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
        do {
            let response: ReferralData = try await network.request("/getReferral")
            referralData = response
            isLoaded = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Request Payout
    func requestPayout(method: String, details: [String: String]) async {
        isLoading = true
        error = nil
        do {
            let body = PayoutRequest(payoutMethod: method, payload: details)
            let _: MessageResponse = try await network.request("/requestPayout", method: "POST", body: body)
            payoutSuccess = true
        } catch {
            self.error = error.localizedDescription
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
