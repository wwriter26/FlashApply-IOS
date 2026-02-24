import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    let email: String
    let password: String
    @State private var code = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.flashTeal)
                    .padding(.top, 60)

                Text("Check Your Email")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.flashNavy)

                Text("We sent a 6-digit verification code to\n**\(email)**")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)

                // 6-digit code field
                TextField("6-digit code", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 48)
                    .onChange(of: code) { oldValue, newValue in
                        code = String(newValue.filter(\.isNumber).prefix(6))
                    }

                if let error = authVM.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: handleVerification) {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Verify Email")
                    }
                }
                .primaryButtonStyle()
                .padding(.horizontal, 24)
                .disabled(code.count < 6 || authVM.isLoading)

                Button("Resend Code") {
                    Task { await authVM.forgotPassword(email: email) }
                }
                .foregroundColor(.flashTeal)
                .font(.subheadline)
            }
        }
        .background(Color.flashBackground.ignoresSafeArea())
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private func handleVerification() {
        Task {
            let success = await authVM.confirmSignUp(email: email, code: code)
            if success {
                // Auto sign-in so AppRouter transitions directly to PreferencesQuizView
                await authVM.signIn(email: email, password: password)
            }
        }
    }
}
