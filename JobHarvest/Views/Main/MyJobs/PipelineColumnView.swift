import SwiftUI
import Combine

struct PipelineColumnView: View {
    let stage: PipelineStage
    let jobs: [AppliedJob]
    let onJobTap: (AppliedJob) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column Header
            HStack {
                Circle()
                    .fill(stage.color)
                    .frame(width: 10, height: 10)
                Text(stage.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.flashNavy)
                Spacer()
                Text("\(jobs.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(stage.color)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(stage.color.opacity(0.08))
            .cornerRadius(10)

            // Job Cards
            if jobs.isEmpty {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .frame(width: 200, height: 100)
                    .overlay(
                        Text("No jobs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            } else {
                ForEach(jobs) { job in
                    PipelineJobCard(job: job)
                        .onTapGesture { onJobTap(job) }
                }
            }
        }
        .frame(width: 200)
    }
}

struct PipelineJobCard: View {
    let job: AppliedJob

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                CompanyLogoView(domain: job.companyData?.logoDomain ?? job.companyId, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(job.companyName ?? "Company")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.flashNavy)
                        .lineLimit(1)
                    Text(job.jobTitle ?? "Job Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            if let loc = job.jobLocation {
                Label(loc, systemImage: "mappin")
                    .font(.system(size: 10))
                    .foregroundColor(.flashTextSecondary)
                    .lineLimit(1)
            }

            if let pay = job.payEstimate {
                Text(pay.formattedString)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.flashOrange)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
