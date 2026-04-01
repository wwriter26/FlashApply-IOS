import SwiftUI
import SDWebImageSwiftUI

// Fetches company logo from logo.dev using a domain (e.g. "google.com").
// Pass companyData?.logoDomain for best results; falls back to companyId.
// Shows a building placeholder on failure.
// Uses SDWebImageSwiftUI for automatic memory + disk caching.
struct CompanyLogoView: View {
    let domain: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let domain = domain, !domain.isEmpty,
               let url = URL(string: "https://img.logo.dev/\(domain)?token=pk_a%5DMObGMfQ7y1P0eKVOGwiw&size=100&format=png") {
                WebImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(size * 0.2)
    }

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Color.flashTeal.opacity(0.15))
            Image(systemName: "building.2.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.flashTeal)
        }
    }
}
