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
        guard profileVM.isLoaded else { return true }
        guard let name = profileVM.profile.resumeFileName else { return false }
        return !name.isEmpty
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
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(remaining) left")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(remaining <= 5 ? .flashOrange : .flashTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            (remaining <= 5 ? Color.flashOrange : Color.flashTeal).opacity(0.12)
                        )
                        .clipShape(Capsule())
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
    private var emptyView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.flashTextSecondary.opacity(0.4), Color.flashTextSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.flashTextSecondary.opacity(0.08))
                    .frame(width: 90, height: 90)

                Image(systemName: "rectangle.stack.badge.minus")
                    .font(.system(size: 40))
                    .foregroundColor(.flashTextSecondary)
            }

            VStack(spacing: 8) {
                Text("No more jobs right now")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.flashNavy)
                Text("Check back later or adjust your filters to see more opportunities.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .foregroundColor(.flashTextSecondary)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            Button("Refresh") {
                Task { await jobCardsVM.fetchJobs(filters: currentFilters) }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Color.flashTeal, Color.flashTealDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.flashTeal.opacity(0.35), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)
        }
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
