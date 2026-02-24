import Foundation
import Combine

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var isLoading = false
    @Published var error: String?
    @Published var checkoutURL: URL?

    private let network = NetworkService.shared

    // MARK: - Create Checkout Session (returns web URL for Option A)
    func createCheckoutSession(plan: SubscriptionPlan) async {
        isLoading = true
        error = nil
        do {
            struct CheckoutBody: Encodable { let planChosen: String }
            let response: CheckoutSessionResponse = try await network.request(
                "/createCheckoutSession",
                method: "POST",
                body: CheckoutBody(planChosen: plan.rawValue)
            )
            if let urlString = response.url, let url = URL(string: urlString) {
                checkoutURL = url
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Check Session Status
    func checkSessionStatus(sessionId: String) async {
        do {
            let response: SessionStatusResponse = try await network.requestWithParams(
                "/sessionStatus",
                params: ["session_id": sessionId]
            )
            if let planStr = response.plan, let plan = SubscriptionPlan(rawValue: planStr) {
                currentPlan = plan
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Cancel Subscription
    func cancelSubscription() async -> Bool {
        isLoading = true
        do {
            let _: MessageResponse = try await network.request("/cancelSubscription", method: "POST")
            currentPlan = .free
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
