import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showVerification = false
    @State private var registeredEmail = ""

    private var passwordsMatch: Bool { password == confirmPassword }
    private var formValid: Bool {
        !name.isEmpty && email.isValidEmail && password.count >= 8 && passwordsMatch
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.flashWhite, Color.flashTeal.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.flashNavy)
                            .padding(.top, 40)
                        Text("Start applying to jobs instantly")
                            .font(.subheadline)
                            .foregroundColor(.flashTextSecondary)
                    }

                    VStack(spacing: 16) {
                        AuthTextField(
                            placeholder: "Full Name",
                            text: $name,
                            contentType: .name,
                            keyboardType: .default,
                            isSecure: false
                        )

                        AuthTextField(
                            placeholder: "Email address",
                            text: $email,
                            contentType: .emailAddress,
                            keyboardType: .emailAddress,
                            isSecure: false
                        )

                        AuthTextField(
                            placeholder: "Password (min 8 characters)",
                            text: $password,
                            contentType: .newPassword,
                            keyboardType: .default,
                            isSecure: true
                        )

                        AuthTextField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            contentType: .newPassword,
                            keyboardType: .default,
                            isSecure: true
                        )

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords do not match")
                                .foregroundColor(.red)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        if !name.isEmpty || !email.isEmpty || !password.isEmpty || !confirmPassword.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                if !email.isEmpty && !email.isValidEmail {
                                    Text("Enter a valid email address")
                                        .foregroundColor(.red).font(.caption)
                                }
                                if !password.isEmpty && password.count < 8 {
                                    Text("Password must be at least 8 characters")
                                        .foregroundColor(.red).font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        }

                        if let error = authVM.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        Button(action: handleSignUp) {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                            }
                        }
                        .primaryButtonStyle()
                        .opacity(formValid ? 1.0 : 0.5)
                        .disabled(!formValid || authVM.isLoading)

                        Text("By creating an account, you agree to our Terms of Service and Privacy Policy.")
                            .font(.caption)
                            .foregroundColor(.flashTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showVerification) {
            EmailVerificationView(email: registeredEmail, password: password)
        }
    }

    private func handleSignUp() {
        Task {
            let success = await authVM.signUp(email: email, password: password, name: name)
            if success {
                registeredEmail = email
                showVerification = true
            }
        }
    }
}
