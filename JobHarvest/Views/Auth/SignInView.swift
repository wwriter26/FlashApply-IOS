import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.flashWhite, Color.flashTeal.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection

                        VStack(spacing: 16) {
                            AuthTextField(
                                placeholder: "Email address",
                                text: $email,
                                contentType: .emailAddress,
                                keyboardType: .emailAddress,
                                isSecure: false
                            )

                            AuthTextField(
                                placeholder: "Password",
                                text: $password,
                                contentType: .password,
                                keyboardType: .default,
                                isSecure: true
                            )

                            if let error = authVM.error {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                            }

                            Button(action: { Task { await authVM.signIn(email: email, password: password) } }) {
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sign In")
                                }
                            }
                            .primaryButtonStyle()
                            .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)

                            Button("Forgot Password?") { showForgotPassword = true }
                                .foregroundColor(.flashTeal)
                                .font(.subheadline)
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                        dividerSection
                            .padding(.top, 28)

                        VStack(spacing: 12) {
                            Button(action: { Task { await authVM.signInWithApple() } }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 17, weight: .semibold))
                                    Text("Continue with Apple")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)

                            Button(action: { Task { await authVM.signInWithGoogle() } }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 17, weight: .semibold))
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(Color.flashDark)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.flashTextSecondary)
                            Button("Sign Up") { showSignUp = true }
                                .foregroundColor(.flashTeal)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .padding(.top, 28)
                        .padding(.bottom, 48)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignUp) { SignUpView() }
            .navigationDestination(isPresented: $showForgotPassword) { ForgotPasswordView() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image("jobHarvestTransparent")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .padding(.top, 56)

            Text("JobHarvest")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.flashNavy)

            Text("Apply to jobs at lightning speed")
                .font(.subheadline)
                .foregroundColor(.flashTextSecondary)
                .padding(.bottom, 4)
        }
    }

    private var dividerSection: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.25))
            Text("OR")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.flashTextSecondary)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.25))
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Shared auth text field component
struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let contentType: UITextContentType
    let keyboardType: UIKeyboardType
    let isSecure: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(contentType)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(contentType)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.flashTeal.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
