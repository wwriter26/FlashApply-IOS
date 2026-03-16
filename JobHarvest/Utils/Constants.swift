import SwiftUI

// MARK: - API
enum AppConfig {
    static let apiDomain: String = {
        guard let value = Bundle.main.infoDictionary?["API_DOMAIN"] as? String,
              !value.isEmpty else {
            #if DEBUG
            fatalError("API_DOMAIN is missing or empty in Config.xcconfig / Info.plist. Copy Config.xcconfig.template to Config.xcconfig and set API_DOMAIN.")
            #else
            return "https://jobharvest-api.com/v1"
            #endif
        }
        return value.hasPrefix("http") ? value : "https://\(value)"
    }()
    static let stripePublishableKey = Bundle.main.infoDictionary?["STRIPE_KEY"] as? String ?? ""
    static let bucketName = Bundle.main.infoDictionary?["BUCKET_NAME"] as? String ?? ""
}

// MARK: - Colors
extension Color {
    static let flashTeal     = Color(hex: "#1abc9c")
    static let flashNavy     = Color(hex: "#1a237e")
    static let flashDark     = Color(hex: "#2c3e50")
    static let flashTealDark = Color(hex: "#16a085")
    static let flashOrange   = Color(hex: "#e67e22")
    static let flashBackground = Color(hex: "#F5F5F5")
    static let flashTextSecondary = Color(hex: "#7f8c8d")
    static let flashWhite    = Color(hex: "#FAFAFA")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Pipeline Stage Labels
extension PipelineStage {
    var displayName: String {
        switch self {
        case .applying:  return "Applying"
        case .applied:   return "Applied"
        case .screen:    return "Screening"
        case .interview: return "Interview"
        case .offer:     return "Offer"
        case .archived:  return "Archived"
        case .failed:    return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .applying:  return .flashTeal
        case .applied:   return Color(hex: "#2ecc71")
        case .screen:    return Color(hex: "#3498db")
        case .interview: return Color(hex: "#9b59b6")
        case .offer:     return Color(hex: "#f1c40f")
        case .archived:  return .flashTextSecondary
        case .failed:    return Color(hex: "#e74c3c")
        }
    }
}
