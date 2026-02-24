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
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.flashNavy)
                        .padding(.top, 40)
                    Text("Start applying to jobs instantly")
                        .font(.subheadline)
                        .foregroundColor(.flashTextSecondary)
                }

                VStack(spacing: 16) {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    SecureField("Password (min 8 characters)", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let error = authVM.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: handleSignUp) {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(!formValid || authVM.isLoading)

                    Text("By creating an account, you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
        .background(Color.flashBackground.ignoresSafeArea())
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
