import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Logo / Header
                    headerSection

                    // Form
                    VStack(spacing: 16) {
                        TextField("Email address", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        if let error = authVM.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        Text("OR").font(.caption).foregroundColor(.gray)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                    // Social Sign-In
                    VStack(spacing: 12) {
                        Button(action: { Task { await authVM.signInWithApple() } }) {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Continue with Apple")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button(action: { Task { await authVM.signInWithGoogle() } }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Continue with Google")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                    }
                    .padding(.horizontal, 24)

                    // Sign Up
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign Up") { showSignUp = true }
                            .foregroundColor(.flashTeal)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.flashBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $showSignUp) { SignUpView() }
            .navigationDestination(isPresented: $showForgotPassword) { ForgotPasswordView() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 48))
                .foregroundColor(.flashTeal)
                .padding(.top, 60)
            Text("JobHarvest")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.flashNavy)
            Text("Apply to jobs at lightning speed")
                .font(.subheadline)
                .foregroundColor(.flashTextSecondary)
                .padding(.bottom, 8)
        }
    }
}
