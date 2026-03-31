import Foundation
import Combine
import os

@MainActor
final class SubscriptionViewModel: ObservableObject {
    nonisolated init() {}
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var isLoading = false
    @Published var error: String?
    @Published var checkoutURL: URL?

    private let network = NetworkService.shared

    // MARK: - Create Checkout Session
    func createCheckoutSession(plan: SubscriptionPlan) async {
        isLoading = true
        error = nil
        checkoutURL = nil
        AppLogger.subscription.debug("createCheckoutSession: plan = \(plan.rawValue)")
        do {
            struct CheckoutBody: Encodable { let planChosen: String }
            let wrapper: APIResponse<CheckoutSessionResponse> = try await network.request(
                "/createCheckoutSession",
                method: "POST",
                body: CheckoutBody(planChosen: plan.rawValue)
            )
            let response = wrapper.data
            if let urlString = response?.url, let url = URL(string: urlString) {
                // Backend returned a checkout URL — open in Safari.
                checkoutURL = url
                AppLogger.subscription.info("createCheckoutSession: checkout URL ready for \(plan.rawValue)")
            } else if let sessionId = response?.sessionId, !sessionId.isEmpty {
                // No URL but we have a session ID — build hosted checkout URL.
                if let url = URL(string: "https://checkout.stripe.com/c/pay/\(sessionId)") {
                    checkoutURL = url
                    AppLogger.subscription.info("createCheckoutSession: built checkout URL from sessionId for \(plan.rawValue)")
                }
            } else {
                AppLogger.subscription.error("createCheckoutSession: response had no url or sessionId — \(String(describing: response))")
                self.error = "Could not start checkout. Please try again."
            }
        } catch {
            AppLogger.subscription.error("createCheckoutSession: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }
        isLoading = false
    }

    // MARK: - Check Session Status
    func checkSessionStatus(sessionId: String) async {
        AppLogger.subscription.debug("checkSessionStatus: session_id = \(sessionId)")
        do {
            let response: SessionStatusResponse = try await network.requestWithParams(
                "/sessionStatus",
                params: ["session_id": sessionId]
            )
            if let planStr = response.plan, let plan = SubscriptionPlan(rawValue: planStr) {
                currentPlan = plan
                AppLogger.subscription.info("checkSessionStatus: plan updated to \(plan.rawValue)")
            } else {
                AppLogger.subscription.error("checkSessionStatus: response had no recognizable plan — \(String(describing: response.plan))")
            }
        } catch {
            AppLogger.subscription.error("checkSessionStatus: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }
    }

    // MARK: - Cancel Subscription
    func cancelSubscription() async -> Bool {
        isLoading = true
        AppLogger.subscription.debug("cancelSubscription: sending request")
        do {
            let _: MessageResponse = try await network.request("/cancelSubscription", method: "POST")
            currentPlan = .free
            AppLogger.subscription.info("cancelSubscription: success — plan set to free")
            isLoading = false
            return true
        } catch {
            AppLogger.subscription.error("cancelSubscription: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
            isLoading = false
            return false
        }
    }
}
