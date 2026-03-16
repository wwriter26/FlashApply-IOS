import SwiftUI
import Amplify

// MARK: - AppRouter
// Central auth-gated navigation. Mirrors the React Hub.listen pattern.
struct AppRouter: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var jobCardsVM: JobCardsViewModel
    @EnvironmentObject var appliedJobsVM: AppliedJobsViewModel
    @EnvironmentObject var mailboxVM: MailboxViewModel
    @State private var hubToken: UnsubscribeToken?
    @State private var showPostOnboardingLoading = false

    var body: some View {
        Group {
            if !authVM.isLoaded {
                LoadingView(message: "Loading...")
            } else if !authVM.isSignedIn {
                SignInView()
            } else if authVM.isNewUser {
                PreferencesQuizView()
            } else if showPostOnboardingLoading {
                LoadingView(message: "Getting things ready...")
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isLoaded)
        .animation(.easeInOut(duration: 0.3), value: authVM.isSignedIn)
        .onChange(of: authVM.isSignedIn) { isSignedIn in
            if !isSignedIn {
                profileVM.reset()
                jobCardsVM.reset()
                appliedJobsVM.reset()
                mailboxVM.reset()
            }
        }
        .onChange(of: authVM.isNewUser) { isNewUser in
            if !isNewUser && authVM.isSignedIn {
                showPostOnboardingLoading = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    showPostOnboardingLoading = false
                }
            }
        }
        .task {
            await authVM.checkAuthState()
            listenToAuthEvents()
        }
        .onDisappear {
            if let token = hubToken {
                Amplify.Hub.removeListener(token)
            }
        }
    }

    // MARK: - Amplify Hub Listener
    private func listenToAuthEvents() {
        hubToken = Amplify.Hub.listen(to: .auth) { payload in
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
