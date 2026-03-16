import Foundation
import Combine
import UIKit
import os
import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore
import SwiftUI

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case notSignedIn
    case sessionExpired
    case noIdentityId
    case confirmationRequired
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:          return "You are not signed in."
        case .sessionExpired:       return "Your session has expired. Please sign in again."
        case .noIdentityId:         return "Could not retrieve identity. Please sign in again."
        case .confirmationRequired: return "Please verify your email before signing in."
        case .unknown(let msg):     return msg
        }
    }
}

// MARK: - AuthService
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    private init() {}

    // MARK: Sign Up
    func signUp(email: String, password: String, name: String) async throws {
        let userAttributes = [AuthUserAttribute(.email, value: email),
                              AuthUserAttribute(.name, value: name),
                              AuthUserAttribute(AuthUserAttributeKey.custom("firstLogin"), value: "true")]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        let result = try await Amplify.Auth.signUp(username: email, password: password, options: options)
        AppLogger.auth.info("SignUp result: \(String(describing: result.nextStep))")
    }

    // MARK: Confirm Sign Up
    func confirmSignUp(email: String, code: String) async throws {
        let result = try await Amplify.Auth.confirmSignUp(for: email, confirmationCode: code)
        AppLogger.auth.info("ConfirmSignUp: \(String(describing: result))")
    }

    // MARK: Sign In
    func signIn(email: String, password: String) async throws {
        AppLogger.auth.debug("signIn: attempting for \(email)")
        let result = try await Amplify.Auth.signIn(username: email, password: password)
        guard result.isSignedIn else {
            AppLogger.auth.error("signIn: nextStep requires confirmation — \(String(describing: result.nextStep))")
            throw AuthError.confirmationRequired
        }
        AppLogger.auth.info("signIn: success for \(email)")
    }

    // MARK: Sign Out
    func signOut() async {
        AppLogger.auth.debug("signOut: initiating")
        let result = await Amplify.Auth.signOut()
        if let error = (result as? AWSCognitoSignOutResult).flatMap({
            if case .failed(let e) = $0 { return e } else { return nil }
        }) {
            AppLogger.auth.error("signOut: error — \(error.localizedDescription)")
        } else {
            AppLogger.auth.info("signOut: success")
        }
    }

    // MARK: Resend Sign Up Code
    func resendSignUpCode(email: String) async throws {
        AppLogger.auth.debug("resendSignUpCode: resending to \(email)")
        let result = try await Amplify.Auth.resendSignUpCode(for: email)
        AppLogger.auth.info("resendSignUpCode: delivery — \(String(describing: result))")
    }

    // MARK: Forgot Password
    func forgotPassword(email: String) async throws {
        AppLogger.auth.debug("forgotPassword: sending reset code to \(email)")
        let result = try await Amplify.Auth.resetPassword(for: email)
        AppLogger.auth.info("forgotPassword: nextStep — \(String(describing: result.nextStep))")
    }

    func confirmForgotPassword(email: String, code: String, newPassword: String) async throws {
        AppLogger.auth.debug("confirmForgotPassword: confirming reset for \(email)")
        try await Amplify.Auth.confirmResetPassword(for: email, with: newPassword, confirmationCode: code)
        AppLogger.auth.info("confirmForgotPassword: success for \(email)")
    }

    // MARK: Change Password
    func changePassword(old: String, new: String) async throws {
        AppLogger.auth.debug("changePassword: updating password")
        try await Amplify.Auth.update(oldPassword: old, to: new)
        AppLogger.auth.info("changePassword: success")
    }

    // MARK: Sign In With Apple
    func signInWithApple() async throws {
        let result = try await Amplify.Auth.signInWithWebUI(for: .apple, presentationAnchor: try keyWindow())
        AppLogger.auth.info("Apple sign-in: \(String(describing: result))")
    }

    // MARK: Google Sign In
    func signInWithGoogle() async throws {
        let result = try await Amplify.Auth.signInWithWebUI(for: .google, presentationAnchor: try keyWindow())
        AppLogger.auth.info("Google sign-in: \(String(describing: result))")
    }

    private func keyWindow() throws -> UIWindow {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .filter({ $0.activationState == .foregroundActive })
            .first?
            .keyWindow
        else {
            throw AuthError.unknown("No active window found for sign-in presentation.")
        }
        return window
    }

    // MARK: Token Retrieval
    func getIdToken() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            AppLogger.auth.error("getIdToken: session is not a Cognito session")
            throw AuthError.sessionExpired
        }
        do {
            let tokens = try cognitoSession.getCognitoTokens().get()
            return tokens.idToken
        } catch {
            AppLogger.auth.error("getIdToken: token extraction failed — \(error.localizedDescription)")
            throw AuthError.sessionExpired
        }
    }

    func getAccessToken() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            AppLogger.auth.error("getAccessToken: session is not a Cognito session")
            throw AuthError.sessionExpired
        }
        do {
            let tokens = try cognitoSession.getCognitoTokens().get()
            return tokens.accessToken
        } catch {
            AppLogger.auth.error("getAccessToken: token extraction failed — \(error.localizedDescription)")
            throw AuthError.sessionExpired
        }
    }

    func getIdentityId() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard let identitySession = session as? AWSAuthCognitoSession else {
            AppLogger.auth.error("getIdentityId: session is not a Cognito session")
            throw AuthError.noIdentityId
        }
        do {
            let identityId = try identitySession.getIdentityId().get()
            return identityId
        } catch {
            AppLogger.auth.error("getIdentityId: could not extract identity ID — \(error.localizedDescription)")
            throw AuthError.noIdentityId
        }
    }

    // MARK: Current User
    func getCurrentUserId() async throws -> String {
        let user = try await Amplify.Auth.getCurrentUser()
        return user.userId
    }

    func getUserAttributes() async throws -> [AuthUserAttributeKey: String] {
        let attributes = try await Amplify.Auth.fetchUserAttributes()
        var dict: [AuthUserAttributeKey: String] = [:]
        for attr in attributes {
            dict[attr.key] = attr.value
        }
        return dict
    }

    // MARK: First Login Check
    func isFirstLogin() async -> Bool {
        do {
            let attrs = try await getUserAttributes()
            let key = AuthUserAttributeKey.custom("firstLogin")
            let value = attrs[key]
            AppLogger.auth.debug("isFirstLogin: firstLogin attribute = \(value ?? "nil (not set)")")
            return value != "false"
        } catch {
            AppLogger.auth.error("isFirstLogin: failed to fetch user attributes — \(error.localizedDescription) — defaulting to true (assume new user)")
            return true
        }
    }

    func setFirstLoginFalse() async throws {
        AppLogger.auth.debug("setFirstLoginFalse: updating Cognito attribute")
        let attr = AuthUserAttribute(AuthUserAttributeKey.custom("firstLogin"), value: "false")
        try await Amplify.Auth.update(userAttribute: attr)
        AppLogger.auth.info("setFirstLoginFalse: success")
    }

    // MARK: Update Attributes
    func updateEmail(newEmail: String) async throws {
        AppLogger.auth.debug("updateEmail: requesting change to \(newEmail)")
        let attr = AuthUserAttribute(.email, value: newEmail)
        try await Amplify.Auth.update(userAttribute: attr)
        AppLogger.auth.info("updateEmail: confirmation code sent to \(newEmail)")
    }

    func confirmEmailUpdate(code: String) async throws {
        AppLogger.auth.debug("confirmEmailUpdate: submitting code")
        try await Amplify.Auth.confirm(userAttribute: .email, confirmationCode: code)
        AppLogger.auth.info("confirmEmailUpdate: email updated successfully")
    }

    // MARK: Delete Account
    func deleteAccount() async throws {
        AppLogger.auth.debug("deleteAccount: initiating account deletion")
        try await Amplify.Auth.deleteUser()
        AppLogger.auth.info("deleteAccount: account deleted")
    }

    // MARK: Session Check
    func isSignedIn() async -> Bool {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            AppLogger.auth.debug("isSignedIn: \(session.isSignedIn)")
            return session.isSignedIn
        } catch {
            AppLogger.auth.error("isSignedIn: fetchAuthSession failed — \(error.localizedDescription)")
            return false
        }
    }
}
