import SwiftUI

struct ErrorBannerView: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.flashOrange)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.flashDark)
                .lineLimit(2)
            Spacer()
            if let retry = onRetry {
                Button("Retry", action: retry)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.flashTeal)
            }
        }
        .padding(14)
        .background(Color(hex: "#e74c3c").opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#e74c3c").opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}
