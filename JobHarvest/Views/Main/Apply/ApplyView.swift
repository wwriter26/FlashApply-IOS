import SwiftUI
import UIKit

struct ApplyView: View {
    @EnvironmentObject var jobCardsVM: JobCardsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showFilters = false
    @State private var filters = JobFilters()
    @State private var currentFilters = JobFilters()

    private var isPremium: Bool {
        let plan = profileVM.profile.plan ?? "free"
        return plan == "plus" || plan == "pro"
    }

    private var hasResume: Bool {
        guard profileVM.isLoaded else { return true } // don't block while profile is loading
        guard let name = profileVM.profile.resumeFileName else { return false }
        return !name.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.flashBackground.ignoresSafeArea()

                if jobCardsVM.isEffectivelyLoading {
                    LoadingView(message: "Finding jobs for you...")
                } else if !hasResume {
                    noResumeView
                } else if jobCardsVM.noSwipesLeft {
                    noSwipesView
                } else if jobCardsVM.jobs.isEmpty && jobCardsVM.isLoaded {
                    emptyView
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
                if let remaining = jobCardsVM.swipesRemaining {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("\(remaining) swipes left")
                            .font(.caption)
                            .foregroundColor(.flashTextSecondary)
                    }
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
            }
        }
    }

    // MARK: - No Resume View
    private var noResumeView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.flashOrange.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "doc.badge.exclamationmark")
                    .font(.system(size: 46))
                    .foregroundColor(.flashOrange)
            }
            Text("Resume Required")
                .font(.title2).fontWeight(.bold)
                .foregroundColor(.flashNavy)
            Text("JobHarvest fills out applications on your behalf — you need to upload a resume before you can start swiping.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            NavigationLink(destination: ResumeSection()) {
                Label("Upload Resume", systemImage: "arrow.up.doc.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.flashOrange)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 48)
            .padding(.top, 4)
        }
    }

    // MARK: - Card Deck
    private var cardDeck: some View {
        VStack {
            ZStack {
                ForEach(jobCardsVM.jobs.prefix(3).reversed()) { job in
                    if let topIndex = jobCardsVM.jobs.firstIndex(where: { $0.jobUrl == job.jobUrl }) {
                        JobCardView(
                            job: job,
                            isTopCard: topIndex == 0,
                            stackOffset: CGFloat(topIndex) * 8
                        ) { isAccepting, answers in
                            await swipeJob(job: job, isAccepting: isAccepting, answers: answers)
                        }
                        .zIndex(Double(jobCardsVM.jobs.count - topIndex))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

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
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 60))
                .foregroundColor(.flashTextSecondary)
            Text("No more jobs right now")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.flashNavy)
            Text("Check back later or adjust your filters to see more opportunities.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            Button("Refresh") {
                Task { await jobCardsVM.fetchJobs(filters: currentFilters) }
            }
            .primaryButtonStyle()
            .padding(.horizontal, 48)
        }
    }

    private var noSwipesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(.flashOrange)
            Text("Daily Limit Reached")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.flashNavy)
            Text("You've used all your swipes for today. Upgrade to Plus or Pro for more daily swipes.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            NavigationLink(destination: PremiumView()) {
                Text("Upgrade Now")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 48)
        }
    }
}
