import SwiftUI

struct MyJobsView: View {
    @EnvironmentObject var appliedJobsVM: AppliedJobsViewModel
    @State private var selectedJob: AppliedJob?
    @State private var showActiveOnly = true
    @State private var stageMoveMessage: String?

    var displayedStages: [PipelineStage] {
        showActiveOnly ? appliedJobsVM.activeStages : appliedJobsVM.allStages
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $showActiveOnly) {
                    Text("Active").tag(true)
                    Text("All").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemBackground))
                .overlay(alignment: .bottom) { Divider() }

                if appliedJobsVM.isLoading && !appliedJobsVM.isLoaded {
                    LoadingView(message: "Loading your applications...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        if let errorMessage = appliedJobsVM.error {
                            ErrorBannerView(message: errorMessage) {
                                appliedJobsVM.error = nil
                                Task { await appliedJobsVM.fetchAppliedJobs() }
                            }
                            .padding(.top, 10)
                        }

                        if let moveMsg = stageMoveMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "#00c97a"))
                                Text(moveMsg)
                                    .font(.system(size: 14))
                                    .foregroundColor(.flashDark)
                            }
                            .padding(14)
                            .background(Color(hex: "#00c97a").opacity(0.10))
                            .cornerRadius(10)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if displayedStages.allSatisfy({ appliedJobsVM.jobs(for: $0).isEmpty }) {
                            emptyState
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 0) {
                                    ForEach(displayedStages, id: \.self) { stage in
                                        PipelineColumnView(
                                            stage: stage,
                                            jobs: appliedJobsVM.jobs(for: stage),
                                            onJobTap: { job in selectedJob = job }
                                        )
                                        Divider()
                                            .padding(.leading, 16)
                                    }
                                }
                                .padding(.bottom, 32)
                            }
                            .background(Color.flashBackground)
                        }
                    }
                }
            }
            .background(Color.flashBackground)
            .navigationTitle("My Jobs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await appliedJobsVM.fetchAppliedJobs() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .foregroundColor(.flashTeal)
                }
            }
            .sheet(item: $selectedJob) { job in
                JobDetailSheet(job: job, onStageMoved: { message in
                    withAnimation {
                        stageMoveMessage = message
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            stageMoveMessage = nil
                        }
                    }
                })
                .environmentObject(appliedJobsVM)
            }
            .task {
                if !appliedJobsVM.isLoaded {
                    await appliedJobsVM.fetchAppliedJobs()
                } else {
                    await appliedJobsVM.refreshIfStale()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.flashTeal.opacity(0.10))
                    .frame(width: 100, height: 100)
                Image(systemName: "briefcase")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.flashTeal)
            }

            VStack(spacing: 8) {
                Text("No applications yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.flashNavy)
                Text("Start swiping to apply to jobs \u{2014} they\u{2019}ll appear here so you can track your progress.")
                    .font(.system(size: 14))
                    .foregroundColor(.flashDark)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 40)
            }

            Button("Start Swiping") {
                NotificationCenter.default.post(name: .switchToApplyTab, object: nil)
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.flashTeal, Color(hex: "#00a884")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}
