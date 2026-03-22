import SwiftUI

struct PipelineColumnView: View {
    let stage: PipelineStage
    let jobs: [AppliedJob]
    let onJobTap: (AppliedJob) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stage.color)
                        .frame(width: 4, height: 20)

                    Text(stage.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.flashNavy)

                    Spacer()

                    if !jobs.isEmpty {
                        Text("\(jobs.count)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(stage.color)
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.flashTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.22), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(stage.color.opacity(0.05))
            }
            .buttonStyle(.plain)

            if isExpanded {
                if jobs.isEmpty {
                    HStack {
                        Text("No jobs in this stage")
                            .font(.subheadline)
                            .foregroundColor(.flashTextSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.flashBackground)
                } else {
                    VStack(spacing: 10) {
                        ForEach(jobs) { job in
                            Button {
                                onJobTap(job)
                            } label: {
                                PipelineJobCard(job: job)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.flashBackground)
                }
            }
        }
    }
}

struct PipelineJobCard: View {
    let job: AppliedJob

    var body: some View {
        HStack(spacing: 12) {
            CompanyLogoView(
                domain: job.companyData?.logoDomain ?? job.companyId,
                size: 44
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(job.jobTitle ?? "Job Title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.flashNavy)
                    .lineLimit(1)
                Text(job.companyName ?? "Company")
                    .font(.subheadline)
                    .foregroundColor(.flashTextSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                if let pay = job.payEstimate {
                    Text(pay.formattedString)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.flashOrange)
                        .lineLimit(1)
                }
                if let loc = job.jobLocation {
                    Label(loc, systemImage: "mappin")
                        .font(.system(size: 11))
                        .foregroundColor(.flashTextSecondary)
                        .lineLimit(1)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.flashTextSecondary.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .flashCardStyle()
    }
}

// Handles press-down scale feedback without interfering with the Button's tap
// recognition. A simultaneousGesture(DragGesture(minimumDistance: 0)) on the
// card label would compete with the Button's gesture recognizer and prevent
// onTapGesture / Button actions from firing reliably.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
