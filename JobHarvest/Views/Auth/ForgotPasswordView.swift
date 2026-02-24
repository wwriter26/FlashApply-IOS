import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    enum Step { case email, code, done }
    @State private var step: Step = .email
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool { newPassword == confirmPassword }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 52))
                    .foregroundColor(.flashTeal)
                    .padding(.top, 40)

                switch step {
                case .email: emailStep
                case .code:  codeStep
                case .done:  doneStep
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.flashBackground.ignoresSafeArea())
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Step 1: Enter Email
    private var emailStep: some View {
        VStack(spacing: 20) {
            Text("Forgot Password?")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.flashNavy)

            Text("Enter the email address associated with your account and we'll send you a reset code.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("Email address", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            if let error = authVM.error { errorText(error) }

            Button(action: {
                Task {
                    let ok = await authVM.forgotPassword(email: email)
                    if ok { step = .code }
                }
            }) {
                loadingLabel("Send Reset Code")
            }
            .primaryButtonStyle()
            .disabled(email.isEmpty || authVM.isLoading)
        }
    }

    // MARK: - Step 2: Enter Code + New Password
    private var codeStep: some View {
        VStack(spacing: 20) {
            Text("Enter Reset Code")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.flashNavy)

            Text("We sent a code to **\(email)**. Enter it below along with your new password.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("6-digit code", text: $code)
                .keyboardType(.numberPad)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .onChange(of: code) { code = String($0.filter(\.isNumber).prefix(6)) }

            SecureField("New Password", text: $newPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            SecureField("Confirm New Password", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            if !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match").foregroundColor(.red).font(.caption)
            }

            if let error = authVM.error { errorText(error) }

            Button(action: {
                Task {
                    let ok = await authVM.confirmForgotPassword(email: email, code: code, newPassword: newPassword)
                    if ok { step = .done }
                }
            }) {
                loadingLabel("Reset Password")
            }
            .primaryButtonStyle()
            .disabled(code.count < 6 || newPassword.count < 8 || !passwordsMatch || authVM.isLoading)
        }
    }

    // MARK: - Step 3: Done
    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.flashTeal)

            Text("Password Reset!")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.flashNavy)

            Text("Your password has been updated. You can now sign in with your new password.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Back to Sign In") { dismiss() }
                .primaryButtonStyle()
        }
    }

    private func errorText(_ msg: String) -> some View {
        Text(msg).foregroundColor(.red).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func loadingLabel(_ title: String) -> some View {
        if authVM.isLoading { ProgressView().tint(.white) } else { Text(title) }
    }
}
