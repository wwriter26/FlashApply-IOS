import SwiftUI
import Amplify

// MARK: - AppRouter
// Central auth-gated navigation. Mirrors the React Hub.listen pattern.
struct AppRouter: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !authVM.isLoaded {
                LoadingView(message: "Loading...")
            } else if !authVM.isSignedIn {
                SignInView()
            } else if authVM.isNewUser {
                PreferencesQuizView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isLoaded)
        .animation(.easeInOut(duration: 0.3), value: authVM.isSignedIn)
        .task {
            await authVM.checkAuthState()
            listenToAuthEvents()
        }
    }

    // MARK: - Amplify Hub Listener
    private func listenToAuthEvents() {
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                Task { @MainActor in
                    await authVM.checkAuthState()
                }
            case HubPayload.EventName.Auth.signedOut:
                Task { @MainActor in
                    authVM.handleSignOut()
                }
            case HubPayload.EventName.Auth.sessionExpired:
                Task { @MainActor in
                    authVM.handleSignOut()
                }
            default:
                break
            }
        }
    }
}
