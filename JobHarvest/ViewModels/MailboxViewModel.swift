import Foundation
import Combine
import os

@MainActor
final class MailboxViewModel: ObservableObject {
    nonisolated init() {}
    @Published var emails: [Email] = []
    @Published var isLoading = false
    @Published var isLoaded = false
    @Published var isFetchingMore = false
    @Published var hasMore = true
    @Published var error: String?
    @Published var filterTab: FilterTab = .all

    enum FilterTab: String, CaseIterable {
        case all = "All"
        case kept = "Kept"
        case unread = "Unread"
    }

    private let network = NetworkService.shared
    private var bookmarkTimestamp: String?

    var filteredEmails: [Email] {
        switch filterTab {
        case .all:    return emails
        case .kept:   return emails.filter { $0.isKept == true }
        case .unread: return emails.filter { $0.isRead == false }
        }
    }

    var unreadCount: Int { emails.filter { $0.isRead == false }.count }

    // MARK: - Fetch Initial
    func fetchEmails() async {
        isLoading = true
        error = nil
        bookmarkTimestamp = nil
        AppLogger.network.debug("fetchEmails: loading mailbox")
        do {
            let body: [String: String?] = ["bookmarkTimestamp": nil]
            let response: BasicEmailDataResponse = try await network.request(
                "/getBasicEmailData",
                method: "POST",
                body: body
            )
            emails = response.emails ?? []
            bookmarkTimestamp = response.bookmarkTimestamp
            hasMore = response.hasMore ?? false
            isLoaded = true
            AppLogger.network.info("fetchEmails: loaded \(self.emails.count) emails, hasMore=\(self.hasMore)")
        } catch {
            AppLogger.network.error("fetchEmails: failed — \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Load More (pagination)
    func loadMore() async {
        guard hasMore, !isFetchingMore, let bookmark = bookmarkTimestamp else { return }
        isFetchingMore = true
        AppLogger.network.debug("loadMore: fetching next page (bookmark: \(bookmark))")
        do {
            let body = ["bookmarkTimestamp": bookmark]
            let response: BasicEmailDataResponse = try await network.request(
                "/getBasicEmailData",
                method: "POST",
                body: body
            )
            let newCount = response.emails?.count ?? 0
            emails.append(contentsOf: response.emails ?? [])
            bookmarkTimestamp = response.bookmarkTimestamp
            hasMore = response.hasMore ?? false
            AppLogger.network.info("loadMore: appended \(newCount) emails, hasMore=\(self.hasMore)")
        } catch {
            AppLogger.network.error("loadMore: failed — \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        isFetchingMore = false
    }

    // MARK: - Mark Read
    func markRead(emailId: String) async {
        // Optimistic
        updateEmail(emailId: emailId) { $0.isRead = true }
        do {
            let body = ["emailId": emailId]
            let _: MessageResponse = try await network.request(
                "/updateEmailNotification",
                method: "POST",
                body: body
            )
        } catch {
            AppLogger.network.error("markRead: \(error)")
        }
    }

    // MARK: - Toggle Keep
    func toggleKeep(emailId: String) async {
        let currentKept = emails.first(where: { $0.emailId == emailId })?.isKept ?? false
        updateEmail(emailId: emailId) { $0.isKept = !currentKept }
        do {
            let body = ["emailId": emailId]
            let _: MessageResponse = try await network.request(
                "/toggleEmailField",
                method: "POST",
                body: body
            )
        } catch {
            updateEmail(emailId: emailId) { $0.isKept = currentKept } // revert
            AppLogger.network.error("toggleKeep: \(error)")
        }
    }

    // MARK: - Fetch Email Detail
    func fetchEmailDetail(emailId: String) async -> EmailDetail? {
        do {
            let body = ["emailId": emailId]
            let response: SpecificEmailResponse = try await network.request(
                "/getSpecificEmail",
                method: "POST",
                body: body
            )
            return response.email
        } catch {
            AppLogger.network.error("fetchEmailDetail: \(error)")
            return nil
        }
    }

    // MARK: - Helper
    private func updateEmail(emailId: String, update: (inout Email) -> Void) {
        if let idx = emails.firstIndex(where: { $0.emailId == emailId }) {
            update(&emails[idx])
        }
    }
}
