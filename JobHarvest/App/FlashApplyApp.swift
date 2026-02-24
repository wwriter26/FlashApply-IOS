import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin
import os

@main
struct JobHarvestApp: App {
    @StateObject private var authVM = AuthViewModel()

    init() {
        configureAmplify()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authVM)
                .preferredColorScheme(.light)
        }
    }

    // MARK: - Amplify Setup
    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            AppLogger.auth.info("Amplify configured successfully")
        } catch {
            AppLogger.auth.error("Amplify configuration failed: \(error)")
        }
    }
}
