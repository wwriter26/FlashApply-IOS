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
                VStack(alignment: .leading, spacing: 0) {
                    jobHeader

                    VStack(alignment: .leading, spacing: 20) {
                        stagePicker

                        Divider()
                            .padding(.horizontal)

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
                    .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color.flashBackground)
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
        ZStack(alignment: .bottomLeading) {
            let accentColor = (job.stage ?? .applied).color
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.85), accentColor.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)

            HStack(alignment: .bottom, spacing: 14) {
                CompanyLogoView(
                    domain: job.companyData?.logoDomain ?? job.companyId,
                    size: 64
                )
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .offset(y: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(job.jobTitle ?? "Job Title")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text(job.companyName ?? "Company")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            HStack(spacing: 16) {
                Spacer().frame(width: 94)
                if let loc = job.jobLocation {
                    Label(loc, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.flashTextSecondary)
                        .lineLimit(1)
                }
                if let pay = job.payEstimate {
                    Text(pay.formattedString)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.flashOrange)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Stage Picker
    private var stagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pipeline Stage")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.flashTextSecondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PipelineStage.allCases, id: \.self) { stage in
                        Button(action: {
                            selectedStage = stage
                            Task { await appliedJobsVM.moveJob(job, to: stage) }
                        }) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(stage.color)
                                    .frame(width: 7, height: 7)
                                Text(stage.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedStage == stage
                                    ? stage.color.opacity(0.14)
                                    : Color.clear
                            )
                            .foregroundColor(
                                selectedStage == stage ? stage.color : .secondary
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        selectedStage == stage
                                            ? stage.color
                                            : Color.gray.opacity(0.25),
                                        lineWidth: 1.5
                                    )
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: selectedStage)
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
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if let desc = detail.jobDescription {
            Text(desc)
                .font(.callout)
                .lineSpacing(4)
                .foregroundColor(.flashDark)
        } else {
            emptyTabPlaceholder(icon: "doc.text", message: "No description available.")
        }
        if let skills = detail.desiredSkillsTags, !skills.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Desired Skills")
                FlowLayout(items: skills) { skill in
                    Text(skill)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.flashTeal.opacity(0.10))
                        .foregroundColor(.flashTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var requirementsTab: some View {
        if let reqs = detail.jobRequirements, !reqs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Requirements")
                bulletList(reqs)
            }
        }
        if let resps = detail.jobResponsibilities, !resps.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Responsibilities")
                bulletList(resps)
            }
            .padding(.top, 8)
        }
        if (detail.jobRequirements ?? []).isEmpty && (detail.jobResponsibilities ?? []).isEmpty {
            emptyTabPlaceholder(icon: "list.bullet.clipboard", message: "No requirements listed.")
        }
    }

    @ViewBuilder
    private var companyTab: some View {
        if let company = detail.companyData {
            VStack(alignment: .leading, spacing: 14) {
                if let tagline = company.tagline {
                    Text(tagline)
                        .italic()
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let desc = company.description {
                    Text(desc)
                        .font(.callout)
                        .lineSpacing(4)
                        .foregroundColor(.flashDark)
                }

                VStack(spacing: 0) {
                    companyInfoRow("Size",     value: company.size)
                    companyInfoRow("Founded",  value: company.founded)
                    companyInfoRow("HQ",       value: company.headquarters)
                    companyInfoRow("Revenue",  value: company.revenue)
                    companyInfoRow("Type",     value: company.type)
                }
                .background(Color.flashWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)

                if let benefits = company.benefits, !benefits.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Benefits")
                        FlowLayout(items: benefits) { benefit in
                            Text(benefit)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.10))
                                .foregroundColor(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        } else {
            emptyTabPlaceholder(icon: "building.2", message: "No company info available.")
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func companyInfoRow(_ label: String, value: String?) -> some View {
        if let value = value {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.caption)
                    .foregroundColor(.flashDark)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            Divider()
                .padding(.leading, 14)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.flashNavy)
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.flashTeal)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.callout)
                        .lineSpacing(3)
                        .foregroundColor(.flashDark)
                }
            }
        }
    }

    private func emptyTabPlaceholder(icon: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundColor(.flashTextSecondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.flashTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
