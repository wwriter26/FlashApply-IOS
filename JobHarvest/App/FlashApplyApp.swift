import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin
import Sentry
import os

@main
struct JobHarvestApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var jobCardsVM = JobCardsViewModel()
    @StateObject private var appliedJobsVM = AppliedJobsViewModel()
    @StateObject private var mailboxVM = MailboxViewModel()

    init() {
        configureSentry()
        configureAmplify()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authVM)
                .environmentObject(profileVM)
                .environmentObject(jobCardsVM)
                .environmentObject(appliedJobsVM)
                .environmentObject(mailboxVM)
                .preferredColorScheme(.light)
        }
    }

    // MARK: - Sentry Setup
    private func configureSentry() {
        let dsn = AppConfig.sentryDsn
        guard !dsn.isEmpty, dsn != "YOUR_SENTRY_DSN_HERE" else {
            AppLogger.auth.info("Sentry DSN not configured — crash reporting disabled")
            return
        }
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = AppConfig.isDebug ? "debug" : "production"
            options.debug = AppConfig.isDebug
            options.enabled = !AppConfig.isDebug
        }
        AppLogger.auth.info("Sentry configured (environment: \(AppConfig.isDebug ? "debug" : "production"))")
    }

    // MARK: - Amplify Setup
    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            AppLogger.auth.info("Amplify configured successfully")
            AppLogger.network.info("API domain: \(AppConfig.apiDomain)")
        } catch {
            AppLogger.auth.error("Amplify configuration failed: \(error)")
            #if DEBUG
            fatalError("Amplify.configure() failed — verify amplifyconfiguration.json exists and is valid. Error: \(error)")
            #endif
        }
    }
}
