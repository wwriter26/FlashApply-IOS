import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var jobCardsVM: JobCardsViewModel
    @EnvironmentObject var appliedJobsVM: AppliedJobsViewModel
    @EnvironmentObject var mailboxVM: MailboxViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ApplyView()
                .environmentObject(jobCardsVM)
                .environmentObject(profileVM)
                .tabItem {
                    Label("Apply", systemImage: selectedTab == 0 ? "rectangle.stack.fill" : "rectangle.stack")
                }
                .tag(0)

            MyJobsView()
                .environmentObject(appliedJobsVM)
                .tabItem {
                    Label("My Jobs", systemImage: selectedTab == 1 ? "briefcase.fill" : "briefcase")
                }
                .tag(1)

            MailboxView()
                .environmentObject(mailboxVM)
                .tabItem {
                    Label("Mailbox", systemImage: selectedTab == 2 ? "envelope.fill" : "envelope")
                }
                .tag(2)

            ProfileView()
                .environmentObject(profileVM)
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)

            MoreView()
                .environmentObject(profileVM)
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle\(selectedTab == 4 ? ".fill" : "")")
                }
                .tag(4)
        }
        .accentColor(.flashTeal)
        .onAppear {
            configureTabBarAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToApplyTab)) { _ in
            selectedTab = 0
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.flashDark)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.flashTeal)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.flashTeal)]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - More Tab (Settings / Earn / Premium)
struct MoreView: View {
    @State private var showPremium = false
    @State private var showEarn = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: PremiumView()) {
                        Label("Premium Plans", systemImage: "star.fill")
                            .foregroundColor(.flashOrange)
                    }
                    NavigationLink(destination: EarnView()) {
                        Label("Earn & Referrals", systemImage: "gift.fill")
                            .foregroundColor(.flashTeal)
                    }
                }

                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
