import Foundation
import SwiftUI

// MARK: - Date
extension Date {
    static func fromISO(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    func relativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func shortFormatted() -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: self)
    }
}

// MARK: - String
extension String {
    func htmlDecoded() -> String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributed.string
    }

    var isValidEmail: Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: regex, options: .regularExpression) != nil
    }
}

// MARK: - View Modifiers
extension View {
    func flashCardStyle() -> some View {
        self
            .background(Color.flashWhite)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    func primaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.flashTeal)
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(.system(size: 16, weight: .semibold))
    }

    func secondaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.flashTeal.opacity(0.1))
            .foregroundColor(.flashTeal)
            .cornerRadius(10)
            .font(.system(size: 16, weight: .semibold))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.flashTeal, lineWidth: 1)
            )
    }
}

// MARK: - Salary Formatting
extension PayEstimate {
    var formattedString: String {
        guard let min = salaryMin else { return "Salary not listed" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        formatter.maximumFractionDigits = 0
        let minStr = formatter.string(from: NSNumber(value: min)) ?? "\(min)"
        if let max = salaryMax, max > min {
            let maxStr = formatter.string(from: NSNumber(value: max)) ?? "\(max)"
            let period = salaryPeriod ?? "year"
            return "\(minStr) – \(maxStr) / \(period)"
        }
        let period = salaryPeriod ?? "year"
        return "\(minStr) / \(period)"
    }
}
