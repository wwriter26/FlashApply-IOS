import Foundation

// MARK: - Presigned URL Response
struct PresignedURLResponse: Codable {
    let presignedUrl: String?
    let fileName: String?
    let key: String?
}

// MARK: - FileUploadService
final class FileUploadService {
    static let shared = FileUploadService()
    private init() {}

    private let network = NetworkService.shared

    // MARK: - Upload Resume
    func uploadResume(data: Data, fileName: String) async throws -> String {
        // 1. Get presigned URL from backend
        let body = ["fileName": fileName, "fileType": "resume"]
        let response: PresignedURLResponse = try await network.request(
            "/getUploadPresignedUrl",
            method: "POST",
            body: body
        )
        guard let presignedURL = response.presignedUrl,
              let key = response.fileName ?? response.key else {
            throw NetworkError.noData
        }
        // 2. PUT file to S3
        try await network.uploadFile(to: presignedURL, data: data, mimeType: "application/pdf")
        return key
    }

    // MARK: - Upload Transcript
    func uploadTranscript(data: Data, fileName: String) async throws -> String {
        let body = ["fileName": fileName, "fileType": "transcript"]
        let response: PresignedURLResponse = try await network.request(
            "/getUploadPresignedUrl",
            method: "POST",
            body: body
        )
        guard let presignedURL = response.presignedUrl,
              let key = response.fileName ?? response.key else {
            throw NetworkError.noData
        }
        try await network.uploadFile(to: presignedURL, data: data, mimeType: "application/pdf")
        return key
    }

    // MARK: - Get Resume Download URL
    func getResumeLink() async throws -> String {
        struct ResumeLinkResponse: Codable { let url: String? }
        let response: ResumeLinkResponse = try await network.request("/getUserResumeLink")
        guard let url = response.url else { throw NetworkError.noData }
        return url
    }

    // MARK: - Get Transcript Download URL
    func getTranscriptLink() async throws -> String {
        struct LinkResponse: Codable { let url: String? }
        let response: LinkResponse = try await network.request("/getUserTranscriptLink")
        guard let url = response.url else { throw NetworkError.noData }
        return url
    }

    // MARK: - Parse Resume (extract profile data)
    func parseResume(data: Data, fileName: String) async throws -> UserProfile {
        // Upload then parse
        let key = try await uploadResume(data: data, fileName: fileName)
        let body = ["fileName": key]
        let profile: UserProfile = try await network.request("/parseResume", method: "POST", body: body)
        return profile
    }

    // MARK: - Remove Extra Resumes
    func removeResume(fileName: String) async throws {
        let body = ["fileName": fileName]
        let _: MessageResponse = try await network.request("/removeExtraResumes", method: "POST", body: body)
    }

    func removeTranscript(fileName: String) async throws {
        let body = ["fileName": fileName]
        let _: MessageResponse = try await network.request("/removeExtraTranscripts", method: "POST", body: body)
    }
}
