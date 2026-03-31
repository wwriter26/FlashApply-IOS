import Foundation
import Combine

// MARK: - Subscription Tier (Plus vs Pro)
enum SubscriptionTier: String, CaseIterable, Identifiable {
    case plus = "plus"
    case pro  = "pro"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .plus: return "Plus"
        case .pro:  return "Pro"
        }
    }

    var dailySwipes: Int {
        switch self {
        case .plus: return 25
        case .pro:  return 50
        }
    }

    var features: [String] {
        switch self {
        case .plus:
            return ["25 swipes/day", "Advanced matching", "Salary filter", "Priority support"]
        case .pro:
            return ["50 swipes/day", "All Plus features", "Dedicated account manager", "Resume optimization"]
        }
    }
}

// MARK: - Billing Period
enum BillingPeriod: String, CaseIterable, Identifiable {
    case monthly = "monthly"
    case seasonal = "seasonal"
    case lifetime = "lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .seasonal: return "Seasonal"
        case .lifetime: return "Lifetime"
        }
    }
}

// MARK: - Subscription Plan (matches backend MembershipPlan enum)
enum SubscriptionPlan: String, CaseIterable, Identifiable, Comparable {
    case free = "free"
    case monthlyPlus = "monthly-plus"
    case monthlyPro = "monthly-pro"
    case seasonalPlus = "seasonal-plus"
    case seasonalPro = "seasonal-pro"
    case lifetimePlus = "lifetime-plus"
    case lifetimePro = "lifetime-pro"

    var id: String { rawValue }

    /// Ordinal used for upgrade/downgrade comparisons.
    /// Higher rank = better plan. Satisfies Comparable via `<` below.
    var rank: Int {
        switch self {
        case .free:         return 0
        case .monthlyPlus:  return 1
        case .monthlyPro:   return 2
        case .seasonalPlus: return 3
        case .seasonalPro:  return 4
        case .lifetimePlus: return 5
        case .lifetimePro:  return 6
        }
    }

    // Comparable — lets callers write `plan < currentPlan` directly.
    static func < (lhs: SubscriptionPlan, rhs: SubscriptionPlan) -> Bool {
        lhs.rank < rhs.rank
    }

    var tier: SubscriptionTier? {
        switch self {
        case .free: return nil
        case .monthlyPlus, .seasonalPlus, .lifetimePlus: return .plus
        case .monthlyPro, .seasonalPro, .lifetimePro: return .pro
        }
    }

    var billingPeriod: BillingPeriod? {
        switch self {
        case .free: return nil
        case .monthlyPlus, .monthlyPro: return .monthly
        case .seasonalPlus, .seasonalPro: return .seasonal
        case .lifetimePlus, .lifetimePro: return .lifetime
        }
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .monthlyPlus: return "Plus Monthly"
        case .monthlyPro: return "Pro Monthly"
        case .seasonalPlus: return "Plus Seasonal"
        case .seasonalPro: return "Pro Seasonal"
        case .lifetimePlus: return "Plus Lifetime"
        case .lifetimePro: return "Pro Lifetime"
        }
    }

    var dailySwipes: Int {
        tier?.dailySwipes ?? 5
    }

    var price: Double {
        switch self {
        case .free: return 0
        case .monthlyPlus: return 25.0
        case .monthlyPro: return 30.0
        case .seasonalPlus: return 50.0
        case .seasonalPro: return 60.0
        case .lifetimePlus: return 200.0
        case .lifetimePro: return 240.0
        }
    }

    var features: [String] {
        tier?.features ?? ["5 swipes/day", "Basic job matching", "Email notifications"]
    }

    /// Build a plan from tier + billing period
    static func from(tier: SubscriptionTier, period: BillingPeriod) -> SubscriptionPlan {
        switch (tier, period) {
        case (.plus, .monthly): return .monthlyPlus
        case (.plus, .seasonal): return .seasonalPlus
        case (.plus, .lifetime): return .lifetimePlus
        case (.pro, .monthly): return .monthlyPro
        case (.pro, .seasonal): return .seasonalPro
        case (.pro, .lifetime): return .lifetimePro
        }
    }

    /// Match from backend string (e.g. "monthly-plus", "free", "plus", "pro")
    static func fromBackend(_ value: String) -> SubscriptionPlan {
        // Try exact match first
        if let exact = SubscriptionPlan(rawValue: value.lowercased()) {
            return exact
        }
        // Legacy fallback: bare "plus" or "pro" → default to monthly
        switch value.lowercased() {
        case "plus": return .monthlyPlus
        case "pro": return .monthlyPro
        default: return .free
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
