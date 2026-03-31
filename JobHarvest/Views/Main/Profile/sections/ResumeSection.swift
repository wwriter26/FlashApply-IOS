import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import os

struct ResumeSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showDocumentPicker = false
    // Drives the PDF preview sheet — non-nil means "sheet is open for this URL"
    @State private var pdfPreviewURL: URL?
    @State private var isUploading = false
    @State private var isLoadingPreview = false
    @State private var uploadStatus = ""

    var body: some View {
        Form {
            Section("Resume") {
                if let fileName = profileVM.profile.resumeFileName, !fileName.isEmpty {
                    HStack {
                        Image(systemName: "doc.fill").foregroundColor(.flashTeal)
                        VStack(alignment: .leading) {
                            Text(fileName).lineLimit(1)
                            Text("Uploaded").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: { viewResume() }) {
                            if isLoadingPreview {
                                ProgressView()
                                    .frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "eye")
                                    .foregroundColor(.flashTeal)
                            }
                        }
                        .disabled(isLoadingPreview)
                        .accessibilityLabel("View resume")
                    }
                } else {
                    Text("No resume uploaded").foregroundColor(.secondary)
                }

                Button(action: { showDocumentPicker = true }) {
                    Label(profileVM.profile.resumeFileName != nil ? "Replace Resume" : "Upload Resume",
                          systemImage: "arrow.up.doc.fill")
                }
                .foregroundColor(.flashTeal)
                .disabled(isUploading)

                if isUploading {
                    HStack {
                        ProgressView()
                        Text(uploadStatus.isEmpty ? "Uploading..." : uploadStatus)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Text("Upload a PDF resume. JobHarvest uses it to auto-fill job applications and your profile on your behalf.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Resume")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(allowedTypes: [.pdf]) { url in
                uploadResume(from: url)
            }
        }
        // Item-based binding: sheet appears when pdfPreviewURL is non-nil,
        // dismisses (and deallocates the PDFDocument) when set back to nil.
        .sheet(item: $pdfPreviewURL) { url in
            PDFPreviewSheet(url: url)
        }
    }

    private func uploadResume(from url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        isUploading = true
        uploadStatus = "Uploading..."
        Task {
            await profileVM.uploadResume(data: data, fileName: url.lastPathComponent)

            // Parse resume — backend extracts profile data from PDF
            uploadStatus = "Parsing resume..."
            do {
                let identityId = try await AuthService.shared.getIdentityId()
                let body = ["identityId": identityId]
                let _: MessageResponse = try await NetworkService.shared.request("/parseResume", method: "POST", body: body)
                AppLogger.files.info("ResumeSection: parseResume success")
            } catch {
                AppLogger.files.error("ResumeSection: parseResume failed — \(error.localizedDescription)")
            }

            // Re-fetch profile to get parsed data
            await profileVM.fetchProfile()
            isUploading = false
            uploadStatus = ""
        }
    }

    private func viewResume() {
        isLoadingPreview = true
        Task {
            defer { isLoadingPreview = false }
            guard let link = await profileVM.getResumeLink(),
                  let url = URL(string: link) else {
                AppLogger.files.error("ResumeSection: failed to get resume pre-signed URL")
                return
            }
            // Setting this non-nil triggers the .sheet(item:) presentation.
            pdfPreviewURL = url
        }
    }
}

// MARK: - URL + Identifiable

// .sheet(item:) requires Identifiable. The absolute string is a stable, unique
// identity for a URL, which is safe here because the pre-signed URL changes on
// every fetch anyway — we never need to diff two live URLs.
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - PDF Preview Sheet

/// Full-screen sheet wrapper with a Done button so the user can dismiss.
private struct PDFPreviewSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFViewer(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Resume")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - PDFViewer

/// UIViewRepresentable wrapper around PDFKit's PDFView.
/// PDFDocument is initialised once in makeUIView; updateUIView is a no-op
/// because the URL is constant for the lifetime of the sheet.
private struct PDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true          // fills the available width automatically
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // URL is immutable after creation; nothing to update.
    }
}
