import Foundation
import Combine
import Amplify
import os

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoaded = false
    @Published var isSignedIn = false
    @Published var isNewUser = false
    @Published var userId: String = ""
    @Published var email: String = ""
    @Published var emailVerified: Bool = false
    @Published var pendingEmailChange: Bool = false
    @Published var error: String?
    @Published var isLoading = false

    private let auth = AuthService.shared
    private let network = NetworkService.shared

    // MARK: - Check current auth state on app launch
    func checkAuthState() async {
        isLoaded = false
        let signedIn = await auth.isSignedIn()
        if signedIn {
            do {
                let attrs = try await auth.getUserAttributes()
                userId = attrs[.sub] ?? ""
                email = attrs[.email] ?? ""
                emailVerified = attrs[.emailVerified] == "true"
                isNewUser = await auth.isFirstLogin()
                isSignedIn = true
            } catch {
                AppLogger.auth.error("checkAuthState error: \(error)")
                isSignedIn = false
            }
        } else {
            isSignedIn = false
        }
        isLoaded = true
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            try await auth.signIn(email: email, password: password)
            await checkAuthState()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            try await auth.signUp(email: email, password: password, name: name)
            // After signup, call handleNewUser to send welcome email
            let parts = name.split(separator: " ")
            let first = parts.first.map(String.init) ?? name
            let last = parts.dropFirst().joined(separator: " ")
            let body: [String: String] = ["email": email, "firstName": first, "lastName": last]
            let _: MessageResponse = (try? await network.unauthenticatedRequest("/handleNewUser", method: "POST", body: body)) ?? MessageResponse(message: nil, success: nil)
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Confirm Sign Up
    func confirmSignUp(email: String, code: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            try await auth.confirmSignUp(email: email, code: code)
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Sign Out
    func signOut() async {
        await auth.signOut()
        handleSignOut()
    }

    func handleSignOut() {
        isSignedIn = false
        isNewUser = false
        userId = ""
        email = ""
        isLoaded = true
    }

    // MARK: - Forgot Password
    func forgotPassword(email: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            try await auth.forgotPassword(email: email)
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func confirmForgotPassword(email: String, code: String, newPassword: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            try await auth.confirmForgotPassword(email: email, code: code, newPassword: newPassword)
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Sign In with Apple / Google
    func signInWithApple() async {
        isLoading = true
        error = nil
        do {
            try await auth.signInWithApple()
            await checkAuthState()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signInWithGoogle() async {
        isLoading = true
        error = nil
        do {
            try await auth.signInWithGoogle()
            await checkAuthState()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Mark onboarding complete
    func markOnboardingComplete() async {
        try? await auth.setFirstLoginFalse()
        isNewUser = false
    }
}
