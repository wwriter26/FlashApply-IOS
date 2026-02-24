import Foundation
import Combine
import UIKit
import os
import Amplify
import AWSCognitoAuthPlugin
internal import AWSPluginsCore
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
    var objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    
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
        let result = try await Amplify.Auth.signIn(username: email, password: password)
        guard result.isSignedIn else {
            throw AuthError.confirmationRequired
        }
    }

    // MARK: Sign Out
    func signOut() async {
        _ = await Amplify.Auth.signOut()
        AppLogger.auth.info("Signed out")
    }

    // MARK: Forgot Password
    func forgotPassword(email: String) async throws {
        _ = try await Amplify.Auth.resetPassword(for: email)
    }

    func confirmForgotPassword(email: String, code: String, newPassword: String) async throws {
        try await Amplify.Auth.confirmResetPassword(for: email, with: newPassword, confirmationCode: code)
    }

    // MARK: Change Password
    func changePassword(old: String, new: String) async throws {
        try await Amplify.Auth.update(oldPassword: old, to: new)
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
        guard let cognitoSession = session as? AWSAuthCognitoSession,
              let tokens = try? cognitoSession.getCognitoTokens().get() else {
            throw AuthError.sessionExpired
        }
        return tokens.idToken
    }

    func getIdentityId() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard let identitySession = session as? AWSAuthCognitoSession,
              let identityId = try? identitySession.getIdentityId().get() else {
            throw AuthError.noIdentityId
        }
        return identityId
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
        guard let attrs = try? await getUserAttributes() else { return false }
        let key = AuthUserAttributeKey.custom("firstLogin")
        return attrs[key] != "false"
    }

    func setFirstLoginFalse() async throws {
        let attr = AuthUserAttribute(AuthUserAttributeKey.custom("firstLogin"), value: "false")
        try await Amplify.Auth.update(userAttribute: attr)
    }

    // MARK: Update Attributes
    func updateEmail(newEmail: String) async throws {
        let attr = AuthUserAttribute(.email, value: newEmail)
        try await Amplify.Auth.update(userAttribute: attr)
    }

    func confirmEmailUpdate(code: String) async throws {
        try await Amplify.Auth.confirm(userAttribute: .email, confirmationCode: code)
    }

    // MARK: Delete Account
    func deleteAccount() async throws {
        try await Amplify.Auth.deleteUser()
    }

    // MARK: Session Check
    func isSignedIn() async -> Bool {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            return session.isSignedIn
        } catch {
            return false
        }
    }
}
