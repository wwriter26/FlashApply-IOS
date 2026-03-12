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
            AppLogger.network.info("API domain: \(AppConfig.apiDomain)")
        } catch {
            AppLogger.auth.error("Amplify configuration failed: \(error)")
            #if DEBUG
            fatalError("Amplify.configure() failed — verify amplifyconfiguration.json exists and is valid. Error: \(error)")
            #endif
        }
    }
}
