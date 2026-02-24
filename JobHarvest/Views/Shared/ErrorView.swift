import SwiftUI
import Combine

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.flashOrange)
            Text("Something Went Wrong")
                .font(.title3.weight(.bold))
                .foregroundColor(.flashNavy)
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let retry = retryAction {
                Button("Try Again", action: retry)
                    .primaryButtonStyle()
                    .padding(.horizontal, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.flashBackground)
    }
}
