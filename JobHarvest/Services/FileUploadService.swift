import Foundation
import Amplify
import os

// MARK: - FileUploadService
final class FileUploadService {
    static let shared = FileUploadService()
    private init() {}

    private let network = NetworkService.shared

    // MARK: - Upload Resume
    func uploadResume(data: Data, fileName: String) async throws {
        AppLogger.files.debug("uploadResume: \(fileName) (\(data.count) bytes)")
        _ = try await Amplify.Storage.uploadData(
            key: fileName,
            data: data,
            options: .init(accessLevel: .protected, contentType: "application/pdf")
        ).value
        AppLogger.files.info("uploadResume: S3 upload complete — \(fileName)")
    }

    // MARK: - Upload Transcript
    func uploadTranscript(data: Data, fileName: String) async throws {
        AppLogger.files.debug("uploadTranscript: \(fileName) (\(data.count) bytes)")
        _ = try await Amplify.Storage.uploadData(
            key: fileName,
            data: data,
            options: .init(accessLevel: .protected, contentType: "application/pdf")
        ).value
        AppLogger.files.info("uploadTranscript: S3 upload complete — \(fileName)")
    }

    // MARK: - Get Resume Download URL
    func getResumeLink() async throws -> String {
        AppLogger.files.debug("getResumeLink: fetching download URL")
        struct ResumeLinkResponse: Codable { let url: String? }
        let response: ResumeLinkResponse = try await network.request("/getUserResumeLink")
        guard let url = response.url else {
            AppLogger.files.error("getResumeLink: response had no url field")
            throw NetworkError.noData
        }
        return url
    }

    // MARK: - Get Transcript Download URL
    func getTranscriptLink() async throws -> String {
        AppLogger.files.debug("getTranscriptLink: fetching download URL")
        struct LinkResponse: Codable { let url: String? }
        let response: LinkResponse = try await network.request("/getUserTranscriptLink")
        guard let url = response.url else {
            AppLogger.files.error("getTranscriptLink: response had no url field")
            throw NetworkError.noData
        }
        return url
    }

    // MARK: - Parse Resume (extract profile data)
    func parseResume(data: Data, fileName: String) async throws -> UserProfile {
        AppLogger.files.debug("parseResume: uploading \(fileName) then calling /parseResume")
        try await uploadResume(data: data, fileName: fileName)
        let identityId = try await AuthService.shared.getIdentityId()
        AppLogger.files.debug("parseResume: calling /parseResume with identityId")
        let body = ["identityId": identityId]
        let profile: UserProfile = try await network.request("/parseResume", method: "POST", body: body)
        AppLogger.files.info("parseResume: success")
        return profile
    }

    // MARK: - Remove Extra Resumes
    func removeResume(fileName: String) async throws {
        AppLogger.files.debug("removeResume: removing \(fileName)")
        let body = ["fileName": fileName]
        let _: MessageResponse = try await network.request("/removeExtraResumes", method: "POST", body: body)
        AppLogger.files.info("removeResume: removed \(fileName)")
    }

    func removeTranscript(fileName: String) async throws {
        AppLogger.files.debug("removeTranscript: removing \(fileName)")
        let body = ["fileName": fileName]
        let _: MessageResponse = try await network.request("/removeExtraTranscripts", method: "POST", body: body)
        AppLogger.files.info("removeTranscript: removed \(fileName)")
    }
}
