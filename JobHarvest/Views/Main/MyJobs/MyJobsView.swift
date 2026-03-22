import SwiftUI

struct MyJobsView: View {
    @EnvironmentObject var appliedJobsVM: AppliedJobsViewModel
    @State private var selectedJob: AppliedJob?
    @State private var showActiveOnly = true

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
                    LoadingView(message: "Loading your jobs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayedStages.allSatisfy({ appliedJobsVM.jobs(for: $0).isEmpty }) {
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
                JobDetailSheet(job: job)
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
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.flashTeal.opacity(0.10))
                    .frame(width: 100, height: 100)
                Image(systemName: "briefcase")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.flashTeal)
            }

            VStack(spacing: 8) {
                Text("No Applications Yet")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundColor(.flashNavy)
                Text("Swipe right on jobs to start applying.\nYour applications will appear here.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.flashTextSecondary)
                    .lineSpacing(3)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 40)
    }
}
