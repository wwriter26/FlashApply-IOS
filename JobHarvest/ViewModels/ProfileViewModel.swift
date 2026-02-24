import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
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
            let response: UserProfile = try await network.request("/users/\(userId)/profile")
            profile = response
        } catch {
            self.error = error.localizedDescription
        }
        isLoaded = true
        isLoading = false
    }

    // MARK: - Update (full profile patch)
    func updateProfile(_ updatedProfile: UserProfile) async throws {
        isSaving = true
        // Optimistic update
        let previous = profile
        profile = updatedProfile

        do {
            let userId = try await AuthService.shared.getCurrentUserId()
            let _: MessageResponse = try await network.request(
                "/users/\(userId)/profile",
                method: "POST",
                body: updatedProfile
            )
        } catch {
            profile = previous // revert
            isSaving = false
            throw error
        }
        isSaving = false
    }

    // MARK: - Partial Update helpers (called from individual sections)
    func updateField<T: Encodable>(_ keyPath: WritableKeyPath<UserProfile, T>, value: T) async {
        var updated = profile
        updated[keyPath: keyPath] = value
        try? await updateProfile(updated)
    }

    // MARK: - Resume
    func uploadResume(data: Data, fileName: String) async {
        isSaving = true
        do {
            let key = try await FileUploadService.shared.uploadResume(data: data, fileName: fileName)
            profile.resumeFileName = key
            let userId = try await AuthService.shared.getCurrentUserId()
            let _: MessageResponse = try await network.request(
                "/users/\(userId)/profile",
                method: "POST",
                body: profile
            )
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }

    func getResumeLink() async -> String? {
        try? await FileUploadService.shared.getResumeLink()
    }
}
