import SwiftUI
import UniformTypeIdentifiers
import os

struct ResumeSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showDocumentPicker = false
    @State private var resumeURL: URL?
    @State private var isUploading = false
    @State private var showDownload = false
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
                        Button(action: { downloadResume() }) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.flashTeal)
                        }
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
        .alert("Resume Downloaded", isPresented: $showDownload) {
            Button("OK") {}
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

    private func downloadResume() {
        Task {
            if let link = await profileVM.getResumeLink(), let url = URL(string: link) {
                await UIApplication.shared.open(url)
            }
        }
    }
}
