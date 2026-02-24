import Foundation

// MARK: - Mailbox Email (basic list item)
struct Email: Codable, Identifiable {
    var id: String { emailId }

    let emailId: String
    let subject: String?
    let fromName: String?
    let fromEmail: String?
    let companyName: String?
    let jobTitle: String?
    let preview: String?
    let timestamp: String?
    var isRead: Bool?
    var isKept: Bool?
    let bookmarkTimestamp: String?

    var receivedDate: Date? {
        guard let ts = timestamp else { return nil }
        return Date.fromISO(ts)
    }
}

// MARK: - Email Detail
struct EmailDetail: Codable, Identifiable {
    var id: String { emailId }

    let emailId: String
    let subject: String?
    let fromName: String?
    let fromEmail: String?
    let companyName: String?
    let jobTitle: String?
    let htmlContent: String?
    let textContent: String?
    let timestamp: String?
    var isRead: Bool?
    var isKept: Bool?
}

// MARK: - Basic Email Data Response (POST /getBasicEmailData)
struct BasicEmailDataResponse: Codable {
    let emails: [Email]?
    let bookmarkTimestamp: String?
    let hasMore: Bool?
}

// MARK: - Specific Email Response (POST /getSpecificEmail)
struct SpecificEmailResponse: Codable {
    let email: EmailDetail?
}
