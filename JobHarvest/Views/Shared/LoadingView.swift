import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Image("jobHarvestTransparent")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .overlay(
                    LinearGradient(
                        colors: [.flashTeal, .flashNavy],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .mask(
                        Image("jobHarvestTransparent")
                            .resizable()
                            .scaledToFit()
                    )
                )
                .scaleEffect(isAnimating ? 1.15 : 0.95)
                .opacity(isAnimating ? 1.0 : 0.6)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }

            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.flashTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.flashBackground)
    }
}
