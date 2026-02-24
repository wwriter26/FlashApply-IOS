import Foundation
import Combine

// MARK: - Subscription Plan
enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case free = "free"
    case plus = "plus"
    case pro  = "pro"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .pro:  return "Pro"
        }
    }

    var monthlyPrice: Double? {
        switch self {
        case .free: return nil
        case .plus: return 25.0
        case .pro:  return 30.0
        }
    }

    var seasonalPrice: Double? {
        switch self {
        case .free: return nil
        case .plus: return 50.0
        case .pro:  return 60.0
        }
    }

    var lifetimePrice: Double? {
        switch self {
        case .free: return nil
        case .plus: return 200.0
        case .pro:  return 240.0
        }
    }

    var dailySwipes: Int {
        switch self {
        case .free: return 5
        case .plus: return 25
        case .pro:  return 50
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return ["5 swipes/day", "Basic job matching", "Email notifications"]
        case .plus:
            return ["25 swipes/day", "Advanced matching", "Salary filter", "Priority support"]
        case .pro:
            return ["50 swipes/day", "All Plus features", "Dedicated account manager", "Resume optimization"]
        }
    }
}

// MARK: - Checkout Session Response (POST /createCheckoutSession)
struct CheckoutSessionResponse: Codable {
    let clientSecret: String?
    let sessionId: String?
    let url: String?
}

// MARK: - Session Status Response (GET /sessionStatus)
struct SessionStatusResponse: Codable {
    let status: String?
    let plan: String?
    let customerId: String?
}
