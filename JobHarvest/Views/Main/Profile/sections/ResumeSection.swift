import SwiftUI
import UniformTypeIdentifiers

struct ResumeSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showDocumentPicker = false
    @State private var resumeURL: URL?
    @State private var isUploading = false
    @State private var showDownload = false

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
                    HStack { ProgressView(); Text("Uploading...").foregroundColor(.secondary) }
                }
            }

            Section {
                Text("Upload a PDF resume. JobHarvest uses it to auto-fill job applications on your behalf.")
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
        Task {
            await profileVM.uploadResume(data: data, fileName: url.lastPathComponent)
            isUploading = false
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
