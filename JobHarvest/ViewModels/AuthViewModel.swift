import Foundation
import Combine
import Amplify
import os

// NOTE: The local `AuthError` enum declared in AuthService.swift shadows `Amplify.AuthError`
// throughout this module. We catch `any AmplifyError` (the protocol that Amplify.AuthError
// conforms to) instead — it is unambiguous, also carries `errorDescription`, and correctly
// matches every error thrown by Amplify.Auth.* calls that propagate through AuthService.

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
        } catch let authError as any AmplifyError {
            AppLogger.auth.error("signIn failed: \(authError.errorDescription) | recovery: \(authError.recoverySuggestion) | underlying: \(String(describing: authError.underlyingError))")
            self.error = authError.errorDescription
        } catch {
            AppLogger.auth.error("signIn failed: \(error)")
            self.error = error.humanReadableDescription
        }
        isLoading = false
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            try await auth.signUp(email: email, password: password, name: name)

            // Create user record in database
            let parts = name.split(separator: " ")
            let first = parts.first.map(String.init) ?? name
            let last = parts.dropFirst().joined(separator: " ")
            let body: [String: String] = ["email": email, "firstName": first, "lastName": last]
            AppLogger.auth.debug("signUp: calling /handleNewUser for \(email)")
            do {
                let response: MessageResponse = try await network.unauthenticatedRequest("/handleNewUser", method: "POST", body: body)
                AppLogger.auth.info("signUp: /handleNewUser success — \(response.message ?? "no message")")
            } catch {
                AppLogger.auth.error("signUp: /handleNewUser FAILED — \(error.localizedDescription) — user may not exist in database")
            }

            isLoading = false
            return true
        } catch let authError as any AmplifyError {
            AppLogger.auth.error("signUp: Cognito signup failed — \(authError.errorDescription)")
            self.error = authError.errorDescription
            isLoading = false
            return false
        } catch {
            AppLogger.auth.error("signUp: Cognito signup failed — \(error)")
            self.error = error.humanReadableDescription
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
            AppLogger.auth.info("confirmSignUp: email verified for \(email)")
            isLoading = false
            return true
        } catch let authError as any AmplifyError {
            AppLogger.auth.error("confirmSignUp failed: \(authError.errorDescription)")
            self.error = authError.errorDescription
            isLoading = false
            return false
        } catch {
            AppLogger.auth.error("confirmSignUp failed: \(error)")
            self.error = error.humanReadableDescription
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
        // Clear onboarding quiz cached state
        PreferencesQuizView.clearSavedQuizState()
    }

    // MARK: - Resend Sign Up Code
    func resendSignUpCode(email: String) async {
        isLoading = true
        error = nil
        do {
            try await auth.resendSignUpCode(email: email)
            isLoading = false
        } catch let authError as any AmplifyError {
            AppLogger.auth.error("resendSignUpCode failed: \(authError.errorDescription)")
            self.error = authError.errorDescription
            isLoading = false
        } catch {
            AppLogger.auth.error("resendSignUpCode failed: \(error)")
            self.error = error.humanReadableDescription
            isLoading = false
        }
    }

    // MARK: - Forgot Password
    func forgotPassword(email: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            try await auth.forgotPassword(email: email)
            isLoading = false
            return true
        } catch let authError as any AmplifyError {
            AppLogger.auth.error("forgotPassword failed: \(authError.errorDescription)")
            self.error = authError.errorDescription
            isLoading = false
            return false
        } catch {
            AppLogger.auth.error("forgotPassword failed: \(error)")
            self.error = error.humanReadableDescription
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
        } catch let authError as any AmplifyError {
            AppLogger.auth.error("confirmForgotPassword failed: \(authError.errorDescription)")
            self.error = authError.errorDescription
            isLoading = false
            return false
        } catch {
            AppLogger.auth.error("confirmForgotPassword failed: \(error)")
            self.error = error.humanReadableDescription
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
        } catch let authError as any AmplifyError {
            AppLogger.auth.error("signInWithApple failed: \(authError.errorDescription)")
            self.error = authError.errorDescription
        } catch {
            AppLogger.auth.error("signInWithApple failed: \(error)")
            self.error = error.humanReadableDescription
        }
        isLoading = false
    }

    func signInWithGoogle() async {
        isLoading = true
        error = nil
        do {
            try await auth.signInWithGoogle()
            await checkAuthState()
        } catch let authError as any AmplifyError {
            AppLogger.auth.error("signInWithGoogle failed: \(authError.errorDescription)")
            self.error = authError.errorDescription
        } catch {
            AppLogger.auth.error("signInWithGoogle failed: \(error)")
            self.error = error.humanReadableDescription
        }
        isLoading = false
    }

    // MARK: - Mark onboarding complete
    func markOnboardingComplete() async {
        do {
            try await auth.setFirstLoginFalse()
            AppLogger.auth.info("markOnboardingComplete: firstLogin set to false")
        } catch {
            AppLogger.auth.error("markOnboardingComplete: failed to update firstLogin attribute — \(error.localizedDescription)")
        }
        isNewUser = false
    }
}
