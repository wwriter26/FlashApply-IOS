import Foundation

// MARK: - Referral Data (GET /getReferral)
struct ReferralData: Codable {
    let referralCode: String?
    let totalReferrals: Int?
    let pendingPayout: Double?
    let totalEarned: Double?
    let referrals: [ReferralEntry]?
    let subscriptionBonuses: SubscriptionBonuses?
}

struct ReferralEntry: Codable, Identifiable {
    var id: String { userId ?? UUID().uuidString }
    let userId: String?
    let email: String?
    let name: String?
    let joinedDate: String?
    let plan: String?
}

struct SubscriptionBonuses: Codable {
    let emailList: Bool?
    let smsList: Bool?
}

// MARK: - Payout History (GET /getPayouts)
struct PayoutHistory: Codable {
    let payouts: [PayoutEntry]?
}

struct PayoutEntry: Codable, Identifiable {
    var id: String { payoutId ?? UUID().uuidString }
    let payoutId: String?
    let amount: Double?
    let method: String?
    let status: String?
    let requestedDate: String?
    let processedDate: String?
}

// MARK: - Request Payout (POST /requestPayout)
struct PayoutRequest: Codable {
    let payoutMethod: String
    let payload: [String: String]
}
