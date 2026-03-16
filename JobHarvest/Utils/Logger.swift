import Foundation
import os

struct AppLogger {
    private static let subsystem = "com.flashapply.ios"

    static let auth         = Logger(subsystem: subsystem, category: "Auth")
    static let network      = Logger(subsystem: subsystem, category: "Network")
    static let jobs         = Logger(subsystem: subsystem, category: "Jobs")
    static let profile      = Logger(subsystem: subsystem, category: "Profile")
    static let files        = Logger(subsystem: subsystem, category: "Files")
    static let subscription = Logger(subsystem: subsystem, category: "Subscription")
    static let referral     = Logger(subsystem: subsystem, category: "Referral")
    static let ui           = Logger(subsystem: subsystem, category: "UI")

    static func debug(_ message: String, category: Logger = AppLogger.ui) {
#if DEBUG
        category.debug("\(message)")
#endif
    }

    static func error(_ message: String, category: Logger = AppLogger.ui) {
        category.error("\(message)")
    }
}
