import SwiftUI
import UIKit

struct ApplyView: View {
    @EnvironmentObject var jobCardsVM: JobCardsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showFilters = false
    @State private var showSwipeInfo = false
    @State private var filters = JobFilters()
    @State private var currentFilters = JobFilters()

    private var isPremium: Bool {
        let plan = profileVM.profile.plan ?? "free"
        return plan == "plus" || plan == "pro"
    }

    private var hasResume: Bool {
        guard profileVM.isLoaded else { return true }
        guard let name = profileVM.profile.resumeFileName else { return false }
        return !name.isEmpty
    }

    private var hasActiveFilters: Bool {
        currentFilters != JobFilters()
    }

    private var dailySwipeLimit: Int {
        switch profileVM.profile.plan ?? "free" {
        case "plus": return 25
        case "pro": return 50
        default: return 5
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.flashBackground.ignoresSafeArea()
                RadialGradient(
                    colors: [Color.flashTeal.opacity(0.07), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 420
                )
                .ignoresSafeArea()

                if jobCardsVM.isEffectivelyLoading {
                    LoadingView(message: "Finding jobs for you...")
                } else if !hasResume {
                    noResumeView
                } else if jobCardsVM.noSwipesLeft {
                    noSwipesView
                } else if jobCardsVM.jobs.isEmpty && jobCardsVM.isLoaded {
                    emptyDeckView
                } else {
                    cardDeck
                }
            }
            .navigationTitle("Apply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.flashTeal)
                    }
                    .disabled(!hasResume)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    swipeBadge
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterDrawerView(filters: $filters, isPremium: isPremium) {
                    currentFilters = filters
                    Task { await jobCardsVM.fetchJobs(filters: currentFilters) }
                }
            }
            .task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await profileVM.fetchProfile() }
                    if !jobCardsVM.isLoaded {
                        group.addTask { await jobCardsVM.fetchJobs() }
                    }
                }
                // Bridge swipe counts from profile response to jobCardsVM
                if !jobCardsVM.hasSwipeCounts {
                    if let daily = profileVM.profile.swipesLeftToday {
                        jobCardsVM.swipesLeftToday = daily
                    }
                    if let enduring = profileVM.profile.enduringSwipes {
                        jobCardsVM.enduringSwipes = enduring
                    }
                }
            }
        }
    }

    // MARK: - Swipe Badge
    private var swipeBadgeLabel: String {
        if jobCardsVM.hasSwipeCounts {
            return "DS: \(jobCardsVM.swipesLeftToday ?? 0) | ES: \(jobCardsVM.enduringSwipes ?? 0)"
        }
        return "DS: – | ES: –"
    }

    private var swipeBadgeIsLow: Bool {
        (jobCardsVM.totalSwipesLeft ?? dailySwipeLimit) <= 5
    }

    private var swipeBadge: some View {
        Button { showSwipeInfo = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(swipeBadgeLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .fixedSize()
            }
            .foregroundColor(swipeBadgeIsLow ? .flashOrange : .flashTeal)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                (swipeBadgeIsLow ? Color.flashOrange : Color.flashTeal).opacity(0.12)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showSwipeInfo) {
            swipeInfoPopover
        }
    }

    private var swipeInfoPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swipe Counts")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.flashNavy)

            if !jobCardsVM.hasSwipeCounts {
                Text("Swipe on a job to see your remaining counts. The server reports your balance after each swipe.")
                    .font(.system(size: 13))
                    .foregroundColor(.flashTextSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.flashTeal)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Swipes (DS): \(jobCardsVM.hasSwipeCounts ? "\(jobCardsVM.swipesLeftToday ?? 0)" : "–")")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Resets every day. Based on your plan.")
                            .font(.system(size: 12))
                            .foregroundColor(.flashTextSecondary)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "infinity")
                        .foregroundColor(.flashOrange)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enduring Swipes (ES): \(jobCardsVM.hasSwipeCounts ? "\(jobCardsVM.enduringSwipes ?? 0)" : "–")")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Bonus swipes that don't expire. Earned through referrals and promotions.")
                            .font(.system(size: 12))
                            .foregroundColor(.flashTextSecondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .presentationCompactAdaptation(.popover)
    }

    // MARK: - No Resume View
    private var noResumeView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.flashOrange, Color.flashOrange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.flashOrange.opacity(0.10))
                    .frame(width: 90, height: 90)

                Image(systemName: "doc.badge.exclamationmark")
                    .font(.system(size: 42))
                    .foregroundColor(.flashOrange)
            }

            VStack(spacing: 8) {
                Text("Resume Required")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.flashNavy)
                Text("JobHarvest fills out applications on your behalf — you need to upload a resume before you can start swiping.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .foregroundColor(.flashTextSecondary)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            NavigationLink(destination: ResumeSection()) {
                Label("Upload Resume", systemImage: "arrow.up.doc.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [Color.flashOrange, Color(hex: "#d35400")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.flashOrange.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Card Deck
    private var cardDeck: some View {
        VStack {
            if let errorMessage = jobCardsVM.error {
                ErrorBannerView(message: errorMessage) {
                    jobCardsVM.error = nil
                    Task { await jobCardsVM.fetchJobs(filters: currentFilters) }
                }
            }

            ZStack {
                ForEach(jobCardsVM.jobs.prefix(3).reversed()) { job in
                    if let topIndex = jobCardsVM.jobs.firstIndex(where: { $0.jobUrl == job.jobUrl }) {
                        JobCardView(
                            job: job,
                            isTopCard: topIndex == 0,
                            stackOffset: CGFloat(topIndex) * 5
                        ) { isAccepting, answers in
                            await swipeJob(job: job, isAccepting: isAccepting, answers: answers)
                        }
                        .zIndex(Double(jobCardsVM.jobs.count - topIndex))
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
    }

    // MARK: - Swipe Action
    private func swipeJob(job: Job, isAccepting: Bool, answers: [String: String]) async {
        let impact = UIImpactFeedbackGenerator(style: isAccepting ? .medium : .light)
        impact.impactOccurred()
        _ = await jobCardsVM.handleSwipe(job: job, isAccepting: isAccepting, answers: answers)
    }

    // MARK: - Empty / No Swipes Views
    private var emptyDeckView: some View {
        VStack(spacing: 24) {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.flashTeal)

            Text(hasActiveFilters ? "No matches for these filters" : "All caught up!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.flashNavy)

            Text(hasActiveFilters
                 ? "Try adjusting your filters to see more opportunities."
                 : "You've seen all available matches. Check back later for new jobs.")
                .font(.system(size: 14))
                .foregroundColor(.flashDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if hasActiveFilters {
                Button("Adjust Filters") {
                    showFilters = true
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.flashTeal, .flashTealDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.flashTeal.opacity(0.35), radius: 10, x: 0, y: 5)
            } else {
                Button("Refresh Jobs") {
                    Task { await jobCardsVM.fetchJobs(filters: currentFilters) }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.flashTeal, .flashTealDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.flashTeal.opacity(0.35), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.horizontal, 32)
    }

    private var noSwipesView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.flashOrange, Color.flashOrange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.flashOrange.opacity(0.10))
                    .frame(width: 90, height: 90)

                Image(systemName: "bolt.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.flashOrange)
            }

            VStack(spacing: 8) {
                Text("Daily Limit Reached")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.flashNavy)
                Text("You've used all your swipes for today. Upgrade to Plus or Pro for unlimited daily swipes.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .foregroundColor(.flashTextSecondary)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            NavigationLink(destination: PremiumView()) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Upgrade Now")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color.flashOrange, Color(hex: "#d35400")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.flashOrange.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 40)
        }
    }
}
