import SwiftUI

// MARK: - AppRouter
// Central auth-gated navigation. Mirrors the React Hub.listen pattern.
struct AppRouter: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var jobCardsVM: JobCardsViewModel
    @EnvironmentObject var appliedJobsVM: AppliedJobsViewModel
    @EnvironmentObject var mailboxVM: MailboxViewModel
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
        }
    }
}
