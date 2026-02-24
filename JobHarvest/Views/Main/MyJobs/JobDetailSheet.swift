import SwiftUI
import UIKit
import SafariServices

struct JobDetailSheet: View {
    let job: AppliedJob
    @EnvironmentObject var appliedJobsVM: AppliedJobsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStage: PipelineStage
    @State private var showSafari = false
    @State private var selectedTab = 0

    init(job: AppliedJob) {
        self.job = job
        _selectedStage = State(initialValue: job.stage ?? .applied)
    }

    var detail: AppliedJob { appliedJobsVM.selectedJob ?? job }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    jobHeader

                    // Stage Picker
                    stagePicker

                    Divider()

                    // Tab Content
                    Picker("", selection: $selectedTab) {
                        Text("Overview").tag(0)
                        Text("Requirements").tag(1)
                        Text("Company").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    tabContent
                        .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Job Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !job.jobUrl.isEmpty {
                        Button(action: { showSafari = true }) {
                            Image(systemName: "safari")
                        }
                        .foregroundColor(.flashTeal)
                    }
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = URL(string: job.jobUrl) {
                    SafariView(url: url)
                }
            }
            .task {
                appliedJobsVM.selectedJob = job
                await appliedJobsVM.fetchJobDetails(jobUrl: job.jobUrl, companyId: job.companyId)
            }
        }
    }

    // MARK: - Header
    private var jobHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            CompanyLogoView(domain: job.companyData?.logoDomain ?? job.companyId, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(job.jobTitle ?? "Job Title")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.flashNavy)
                Text(job.companyName ?? "Company")
                    .font(.subheadline).foregroundColor(.secondary)
                if let loc = job.jobLocation {
                    Label(loc, systemImage: "mappin.circle")
                        .font(.caption).foregroundColor(.flashTextSecondary)
                }
                if let pay = job.payEstimate {
                    Text(pay.formattedString)
                        .font(.caption.weight(.semibold)).foregroundColor(.flashOrange)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Stage Picker
    private var stagePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pipeline Stage").font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PipelineStage.allCases, id: \.self) { stage in
                        Button(action: {
                            selectedStage = stage
                            Task { await appliedJobsVM.moveJob(job, to: stage) }
                        }) {
                            Text(stage.displayName)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedStage == stage ? stage.color : Color.gray.opacity(0.1))
                                .foregroundColor(selectedStage == stage ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0: overviewTab
        case 1: requirementsTab
        default: companyTab
        }
    }

    @ViewBuilder
    private var overviewTab: some View {
        if appliedJobsVM.selectedJobLoading {
            ProgressView().frame(maxWidth: .infinity)
        } else if let desc = detail.jobDescription {
            Text(desc).font(.callout)
        } else {
            Text("No description available.").foregroundColor(.secondary)
        }
        if let skills = detail.desiredSkillsTags, !skills.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Desired Skills").font(.headline)
                FlowLayout(items: skills) { skill in
                    Text(skill)
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.flashTeal.opacity(0.1))
                        .foregroundColor(.flashTeal)
                        .cornerRadius(6)
                }
            }
        }
    }

    @ViewBuilder
    private var requirementsTab: some View {
        if let reqs = detail.jobRequirements, !reqs.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Requirements").font(.headline)
                ForEach(reqs, id: \.self) { req in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").foregroundColor(.flashTeal)
                        Text(req).font(.callout)
                    }
                }
            }
        }
        if let resps = detail.jobResponsibilities, !resps.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Responsibilities").font(.headline)
                ForEach(resps, id: \.self) { resp in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").foregroundColor(.flashTeal)
                        Text(resp).font(.callout)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var companyTab: some View {
        if let company = detail.companyData {
            VStack(alignment: .leading, spacing: 12) {
                if let tagline = company.tagline { Text(tagline).italic().foregroundColor(.secondary) }
                if let desc = company.description { Text(desc).font(.callout) }
                companyInfoRow("Size", value: company.size)
                companyInfoRow("Founded", value: company.founded)
                companyInfoRow("HQ", value: company.headquarters)
                companyInfoRow("Revenue", value: company.revenue)
                companyInfoRow("Type", value: company.type)
                if let benefits = company.benefits, !benefits.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Benefits").font(.headline)
                        FlowLayout(items: benefits) { benefit in
                            Text(benefit)
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        } else {
            Text("No company info available.").foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func companyInfoRow(_ label: String, value: String?) -> some View {
        if let value = value {
            HStack {
                Text(label).font(.caption.weight(.semibold)).foregroundColor(.secondary)
                Spacer()
                Text(value).font(.caption)
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
