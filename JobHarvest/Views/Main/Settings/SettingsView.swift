import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var jobCardsVM: JobCardsViewModel
    @StateObject private var subscriptionVM = SubscriptionViewModel()
    @State private var showChangeEmail = false
    @State private var showChangePassword = false
    @State private var showDeleteAccount = false
    @State private var showCancelSubscription = false
    @State private var showSignOutConfirm = false

    var body: some View {
        List {
            // Swipe Balance
            Section("Swipe Balance") {
                HStack {
                    Label("Daily Swipes", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    Text(jobCardsVM.hasSwipeCounts ? "\(jobCardsVM.swipesLeftToday ?? 0) remaining" : "–")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Label("Enduring Swipes", systemImage: "infinity")
                    Spacer()
                    Text(jobCardsVM.hasSwipeCounts ? "\(jobCardsVM.enduringSwipes ?? 0) remaining" : "–")
                        .foregroundColor(.secondary)
                }
                if !jobCardsVM.hasSwipeCounts {
                    Text("Swipe on a job to see your balance. Counts update after each swipe.")
                        .font(.caption)
                        .foregroundColor(.flashTextSecondary)
                }
            }

            // Account
            Section("Account") {
                Button("Change Email") { showChangeEmail = true }
                    .foregroundColor(.primary)
                Button("Change Password") { showChangePassword = true }
                    .foregroundColor(.primary)
            }

            // Subscription
            Section("Subscription") {
                HStack {
                    Label("Current Plan", systemImage: "crown.fill")
                        .foregroundColor(.flashOrange)
                    Spacer()
                    Text(SubscriptionPlan.fromBackend(profileVM.profile.plan ?? "free").displayName)
                        .foregroundColor(.secondary)
                }
                NavigationLink(destination: PremiumView()) {
                    Label("Manage Plan", systemImage: "star.fill")
                        .foregroundColor(.flashOrange)
                }
                Button("Cancel Subscription", role: .destructive) {
                    showCancelSubscription = true
                }
            }

            // Notifications
            Section("Notifications") {
                Button("Notification Preferences") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundColor(.primary)
            }

            // App Info
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundColor(.secondary)
                }
                Link("Privacy Policy", destination: URL(string: "https://jobharvest.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://jobharvest.com/terms")!)
            }

            // Danger Zone
            Section {
                Button("Sign Out", role: .destructive) { showSignOutConfirm = true }
                Button("Delete Account", role: .destructive) { showDeleteAccount = true }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showChangeEmail) { ChangeEmailView().environmentObject(authVM) }
        .sheet(isPresented: $showChangePassword) { ChangePasswordView().environmentObject(authVM) }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await authVM.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .confirmationDialog("Cancel Subscription", isPresented: $showCancelSubscription, titleVisibility: .visible) {
            Button("Cancel Subscription", role: .destructive) {
                Task { _ = await subscriptionVM.cancelSubscription() }
            }
            Button("Keep Subscription", role: .cancel) {}
        } message: {
            Text("Your plan will revert to Free at the end of your billing period.")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteAccount, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                Task {
                    try? await AuthService.shared.deleteAccount()
                    authVM.handleSignOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
    }
}

// MARK: - Change Email
struct ChangeEmailView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newEmail = ""
    @State private var code = ""
    @State private var step = 0
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if step == 0 {
                    Section("New Email Address") {
                        TextField("New email", text: $newEmail)
                            .keyboardType(.emailAddress).autocapitalization(.none)
                    }
                } else {
                    Section("Verification Code") {
                        Text("We sent a code to \(newEmail)").foregroundColor(.secondary).font(.caption)
                        TextField("6-digit code", text: $code).keyboardType(.numberPad)
                    }
                }
                if let err = error {
                    Section { Text(err).foregroundColor(.red).font(.caption) }
                }
            }
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(step == 0 ? "Send Code" : "Confirm") {
                        isSaving = true
                        error = nil
                        Task {
                            do {
                                if step == 0 {
                                    try await AuthService.shared.updateEmail(newEmail: newEmail)
                                    step = 1
                                } else {
                                    try await AuthService.shared.confirmEmailUpdate(code: code)
                                    dismiss()
                                }
                            } catch {
                                self.error = error.humanReadableDescription
                            }
                            isSaving = false
                        }
                    }
                    .foregroundColor(.flashTeal)
                    .disabled(isSaving || (step == 0 ? newEmail.isEmpty : code.isEmpty))
                }
            }
        }
    }
}

// MARK: - Change Password
struct ChangePasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var error: String?
    @State private var success = false

    var body: some View {
        NavigationStack {
            Form {
                SecureField("Current Password", text: $oldPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
                if let err = error { Text(err).foregroundColor(.red).font(.caption) }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        error = nil
                        Task {
                            do {
                                try await AuthService.shared.changePassword(old: oldPassword, new: newPassword)
                                success = true
                            } catch {
                                self.error = error.humanReadableDescription
                            }
                            isSaving = false
                        }
                    }
                    .foregroundColor(.flashTeal)
                    .disabled(isSaving || oldPassword.isEmpty || newPassword.count < 8 || newPassword != confirmPassword)
                }
            }
            .alert("Password Updated!", isPresented: $success) {
                Button("OK") { dismiss() }
            }
        }
    }
}
