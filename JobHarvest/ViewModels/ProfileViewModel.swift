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
            let response: UserProfile = try await network.request("/users/\(userId)/profile")
            profile = response
            AppLogger.profile.info("fetchProfile: success — completion \(response.completionPercentage)%")
        } catch {
            AppLogger.profile.error("fetchProfile: failed — \(error.localizedDescription)")
            self.error = error.localizedDescription
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
            self.error = error.localizedDescription
        }
    }

    // MARK: - Resume
    func uploadResume(data: Data, fileName: String) async {
        isSaving = true
        AppLogger.files.debug("uploadResume: \(fileName) (\(data.count) bytes)")
        do {
            try await FileUploadService.shared.uploadResume(data: data, fileName: fileName)
            profile.resumeFileName = fileName
            let userId = try await AuthService.shared.getCurrentUserId()
            let _: MessageResponse = try await network.request(
                "/users/\(userId)/profile",
                method: "POST",
                body: profile
            )
            AppLogger.files.info("uploadResume: profile updated with resume key")
        } catch {
            AppLogger.files.error("uploadResume: failed — \(error.localizedDescription)")
            self.error = error.localizedDescription
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
}
