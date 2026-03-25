import Foundation
import Combine
import os

@MainActor
final class ProfileViewModel: ObservableObject {
    nonisolated init() {}
    @Published var profile = UserProfile()
    @Published var isLoading = false
    @Published var isLoaded = false
    @Published var isSaving = false
    @Published var error: String?

    private let network = NetworkService.shared

    // MARK: - Fetch
    func fetchProfile() async {
        isLoading = true
        error = nil
        do {
            let userId = try await AuthService.shared.getCurrentUserId()
            AppLogger.profile.debug("fetchProfile: GET /users/\(userId)/profile")
            let wrapper: APIResponse<UserProfile> = try await network.request("/users/\(userId)/profile")
            if var data = wrapper.data {
                // Backend doesn't store resumeFileName in profile — check S3 via resume link endpoint
                if data.resumeFileName == nil {
                    if let _ = try? await FileUploadService.shared.getResumeLink() {
                        data.resumeFileName = "Resume"  // file exists in S3
                    }
                }
                profile = data
                AppLogger.profile.info("fetchProfile: success — completion \(data.completionPercentage)%")
            } else {
                AppLogger.profile.error("fetchProfile: response had no data field")
            }
        } catch {
            AppLogger.profile.error("fetchProfile: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }
        isLoaded = true
        isLoading = false
    }

    // MARK: - Update (full profile patch)
    func updateProfile(_ updatedProfile: UserProfile) async throws {
        isSaving = true
        let previous = profile
        profile = updatedProfile  // optimistic

        do {
            let userId = try await AuthService.shared.getCurrentUserId()
            AppLogger.profile.debug("updateProfile: POST /users/\(userId)/profile")
            let _: MessageResponse = try await network.request(
                "/users/\(userId)/profile",
                method: "POST",
                body: updatedProfile
            )
            AppLogger.profile.info("updateProfile: success")
            NotificationCenter.default.post(name: .profileDidSave, object: nil)
        } catch {
            profile = previous  // revert
            AppLogger.profile.error("updateProfile: failed — \(error.localizedDescription) — reverted to previous state")
            isSaving = false
            throw error
        }
        isSaving = false
    }

    // MARK: - Partial Update helpers (called from individual sections)
    func updateField<T: Encodable>(_ keyPath: WritableKeyPath<UserProfile, T>, value: T) async {
        var updated = profile
        updated[keyPath: keyPath] = value
        do {
            try await updateProfile(updated)
        } catch {
            AppLogger.profile.error("updateField: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }
    }

    // MARK: - Resume
    func uploadResume(data: Data, fileName: String) async {
        isSaving = true
        AppLogger.files.debug("uploadResume: \(fileName) (\(data.count) bytes)")
        do {
            try await FileUploadService.shared.uploadResume(data: data, fileName: fileName)
            // Backend doesn't store resumeFileName in the profile — it finds resumes
            // by listing S3 at private/{identityId}/resume/. Just set local state.
            profile.resumeFileName = fileName
            AppLogger.files.info("uploadResume: S3 upload complete, local state updated")
        } catch {
            AppLogger.files.error("uploadResume: failed — \(error.localizedDescription)")
            self.error = error.humanReadableDescription
        }
        isSaving = false
    }

    func getResumeLink() async -> String? {
        do {
            let link = try await FileUploadService.shared.getResumeLink()
            AppLogger.files.debug("getResumeLink: success")
            return link
        } catch {
            AppLogger.files.error("getResumeLink: failed — \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Reset
    func reset() {
        profile = UserProfile()
        isLoaded = false
        isLoading = false
        isSaving = false
        error = nil
    }
}
