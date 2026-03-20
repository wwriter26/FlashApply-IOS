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
                // Active / Inactive toggle
                Picker("View", selection: $showActiveOnly) {
                    Text("Active").tag(true)
                    Text("All").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if appliedJobsVM.isLoading && !appliedJobsVM.isLoaded {
                    LoadingView(message: "Loading your jobs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayedStages.allSatisfy({ appliedJobsVM.jobs(for: $0).isEmpty }) {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Horizontal scrolling pipeline
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(displayedStages, id: \.self) { stage in
                                PipelineColumnView(
                                    stage: stage,
                                    jobs: appliedJobsVM.jobs(for: stage),
                                    onJobTap: { job in selectedJob = job }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
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
            Image(systemName: "briefcase")
                .font(.system(size: 60))
                .foregroundColor(.flashTextSecondary)
            Text("No Applications Yet")
                .font(.title2).fontWeight(.semibold).foregroundColor(.flashNavy)
            Text("Swipe right on jobs to start applying. Your applications will appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
    }
}
