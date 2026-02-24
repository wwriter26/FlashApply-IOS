import SwiftUI

// MARK: - Flash Primary Button
struct FlashButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView().tint(.white)
            } else {
                Text(title).fontWeight(.semibold)
            }
        }
        .primaryButtonStyle()
        .disabled(isLoading)
    }
}

// MARK: - Flash Secondary Button
struct FlashSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).fontWeight(.semibold)
        }
        .secondaryButtonStyle()
    }
}

// MARK: - Icon Action Button (for swipe deck)
struct CircleIconButton: View {
    let systemImage: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}
