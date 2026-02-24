import SwiftUI
import UIKit
import WebKit

struct EmailDetailView: View {
    let email: Email
    @EnvironmentObject var mailboxVM: MailboxViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var detail: EmailDetail?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading email...")
                } else if let detail = detail {
                    emailContent(detail)
                } else {
                    Text("Failed to load email.").foregroundColor(.secondary)
                }
            }
            .navigationTitle(email.companyName ?? "Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await mailboxVM.toggleKeep(emailId: email.emailId) } }) {
                        Image(systemName: email.isKept == true ? "bookmark.fill" : "bookmark")
                            .foregroundColor(.flashTeal)
                    }
                }
            }
            .task {
                // Mark read
                await mailboxVM.markRead(emailId: email.emailId)
                // Fetch full content
                detail = await mailboxVM.fetchEmailDetail(emailId: email.emailId)
                isLoading = false
            }
        }
    }

    private func emailContent(_ detail: EmailDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Email header
                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.subject ?? "(No Subject)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.flashNavy)
                    HStack {
                        Text("From:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("\(detail.fromName ?? "") <\(detail.fromEmail ?? "")>")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let jobTitle = detail.jobTitle {
                        Label(jobTitle, systemImage: "briefcase")
                            .font(.caption)
                            .foregroundColor(.flashTeal)
                    }
                    if let ts = email.receivedDate {
                        Text(ts.shortFormatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                Divider()

                // HTML or plain text content
                if let html = detail.htmlContent {
                    HTMLWebView(htmlContent: html)
                        .frame(minHeight: 400)
                        .padding(.horizontal)
                } else if let text = detail.textContent {
                    Text(text)
                        .font(.callout)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - HTML WebView (WKWebView wrapper)
struct HTMLWebView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.scrollView.isScrollEnabled = false
        wv.navigationDelegate = context.coordinator
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        let styledHTML = """
        <html><head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <style>
          body { font-family: -apple-system; font-size: 15px; color: #2c3e50; margin: 0; padding: 0; }
          a { color: #1abc9c; }
          img { max-width: 100%; }
        </style>
        </head><body>\(htmlContent)</body></html>
        """
        wv.loadHTMLString(styledHTML, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
            // Adjust frame to content height
            wv.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                // Height adjustment handled by SwiftUI frame
            }
        }

        func webView(_ wv: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if action.navigationType == .linkActivated, let url = action.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
