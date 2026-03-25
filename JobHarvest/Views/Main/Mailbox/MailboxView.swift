import SwiftUI

struct MailboxView: View {
    @EnvironmentObject var mailboxVM: MailboxViewModel
    @State private var selectedEmail: Email?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter tabs
                Picker("Filter", selection: $mailboxVM.filterTab) {
                    ForEach(MailboxViewModel.FilterTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if mailboxVM.isLoading && !mailboxVM.isLoaded {
                    LoadingView(message: "Loading mailbox...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if mailboxVM.filteredEmails.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emailList
                }

                if let errorMessage = mailboxVM.error {
                    ErrorBannerView(message: errorMessage) {
                        mailboxVM.error = nil
                        Task { await mailboxVM.fetchEmails() }
                    }
                }
            }
            .navigationTitle("Mailbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if mailboxVM.unreadCount > 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("\(mailboxVM.unreadCount) unread")
                            .font(.caption)
                            .foregroundColor(.flashTextSecondary)
                    }
                }
            }
            .sheet(item: $selectedEmail) { email in
                EmailDetailView(email: email)
                    .environmentObject(mailboxVM)
            }
            .task {
                if !mailboxVM.isLoaded {
                    await mailboxVM.fetchEmails()
                }
            }
        }
    }

    private var emailList: some View {
        List {
            ForEach(mailboxVM.filteredEmails) { email in
                EmailRowView(email: email)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedEmail = email }
                    .swipeActions(edge: .trailing) {
                        Button {
                            Task { await mailboxVM.toggleKeep(emailId: email.emailId) }
                        } label: {
                            Label(email.isKept == true ? "Unkeep" : "Keep",
                                  systemImage: email.isKept == true ? "bookmark.slash" : "bookmark")
                        }
                        .tint(.flashTeal)
                    }
                    .onAppear {
                        // Infinite scroll: load more when near bottom
                        if email.emailId == mailboxVM.filteredEmails.last?.emailId {
                            Task { await mailboxVM.loadMore() }
                        }
                    }
            }

            if mailboxVM.isFetchingMore {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await mailboxVM.fetchEmails() }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope")
                .font(.system(size: 60)).foregroundColor(.flashTextSecondary)
            Text("No Emails")
                .font(.title2).fontWeight(.semibold).foregroundColor(.flashNavy)
            Text("Application-related emails will appear here as you apply to jobs.")
                .multilineTextAlignment(.center).foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Email Row
struct EmailRowView: View {
    let email: Email
    var isUnread: Bool { email.isRead == false }

    private var senderDomain: String? {
        guard let addr = email.fromEmail,
              let at = addr.firstIndex(of: "@") else { return nil }
        return String(addr[addr.index(after: at)...])
    }

    var body: some View {
        HStack(spacing: 12) {
            // Company logo with unread dot overlay
            ZStack(alignment: .topLeading) {
                CompanyLogoView(domain: senderDomain, size: 44)
                if isUnread {
                    Circle()
                        .fill(Color.flashTeal)
                        .frame(width: 10, height: 10)
                        .offset(x: -3, y: -3)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(email.companyName ?? email.fromName ?? "Unknown")
                        .font(.subheadline.weight(isUnread ? .bold : .regular))
                        .foregroundColor(.flashNavy)
                        .lineLimit(1)
                    Spacer()
                    Text(email.receivedDate?.relativeString() ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(email.subject ?? "(No Subject)")
                    .font(.callout.weight(isUnread ? .semibold : .regular))
                    .lineLimit(1)
                if let preview = email.preview {
                    Text(preview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if email.isKept == true {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                    .foregroundColor(.flashTeal)
            }
        }
        .padding(.vertical, 4)
    }
}
