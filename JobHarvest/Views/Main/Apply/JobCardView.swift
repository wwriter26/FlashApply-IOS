import SwiftUI
import UIKit

struct JobCardView: View {
    let job: Job
    let isTopCard: Bool
    let stackOffset: CGFloat
    let onSwipe: (Bool, [String: String]) async -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var swipeDirection: SwipeDirection? = nil
    @State private var selectedTab = 0
    @State private var showManualAnswers = false
    @State private var pendingSwipeIsAccepting = false

    private let swipeThreshold: CGFloat = 100

    enum SwipeDirection { case left, right }

    var body: some View {
        ZStack(alignment: .top) {
            cardContent
                .overlay(swipeOverlay)

            if isTopCard {
                actionButtons
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 560)
        .flashCardStyle()
        .offset(x: isTopCard ? dragOffset.width : 0,
                y: (isTopCard ? dragOffset.height * 0.2 : 0) + stackOffset)
        .rotationEffect(.degrees(isTopCard ? Double(dragOffset.width / 20) : 0))
        .scaleEffect(isTopCard ? 1.0 : max(0.95 - stackOffset * 0.005, 0.9))
        .gesture(isTopCard ? dragGesture : nil)
        .sheet(isPresented: $showManualAnswers) {
            ManualAnswersSheet(fields: job.manualInputFields ?? []) { answers in
                Task { await onSwipe(true, answers) }
            }
        }
    }

    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                swipeDirection = value.translation.width > 0 ? .right : .left
            }
            .onEnded { value in
                let threshold = swipeThreshold
                if abs(value.translation.width) > threshold {
                    let isAccepting = value.translation.width > 0
                    withAnimation(.easeOut(duration: 0.3)) {
                        dragOffset = CGSize(
                            width: isAccepting ? 600 : -600,
                            height: value.translation.height
                        )
                    }
                    Task {
                        if isAccepting && !(job.manualInputFields?.isEmpty ?? true) {
                            // Show manual answers sheet before confirming swipe
                            pendingSwipeIsAccepting = true
                            dragOffset = .zero
                            showManualAnswers = true
                        } else {
                            await onSwipe(isAccepting, [:])
                        }
                    }
                } else {
                    withAnimation(.spring()) {
                        dragOffset = .zero
                        swipeDirection = nil
                    }
                }
            }
    }

    // MARK: - Swipe Overlay (Accept/Reject indicators)
    private var swipeOverlay: some View {
        ZStack {
            // Accept overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.2))
                .overlay(
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("APPLY")
                            .font(.title2).fontWeight(.black)
                            .foregroundColor(.green)
                    }
                )
                .opacity(dragOffset.width > 20 ? min(Double(dragOffset.width - 20) / 80, 1.0) : 0)

            // Reject overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.2))
                .overlay(
                    VStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text("SKIP")
                            .font(.title2).fontWeight(.black)
                            .foregroundColor(.red)
                    }
                )
                .opacity(dragOffset.width < -20 ? min(Double(-dragOffset.width - 20) / 80, 1.0) : 0)
        }
    }

    // MARK: - Card Content
    private var cardContent: some View {
        VStack(spacing: 0) {
            cardHeader
            Divider()
            tabContent
        }
    }

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            CompanyLogoView(domain: job.companyData?.logoDomain ?? job.companyId, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(job.jobTitle ?? "Job Title")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.flashNavy)
                    .lineLimit(2)

                Text(job.companyName ?? "Company")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    if let loc = job.jobLocation {
                        Label(loc, systemImage: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(.flashTextSecondary)
                    }
                    if let type = job.jobType {
                        Text(type)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.flashTeal.opacity(0.1))
                            .foregroundColor(.flashTeal)
                            .cornerRadius(6)
                    }
                }

                if let pay = job.payEstimate {
                    Text(pay.formattedString)
                        .font(.caption)
                        .foregroundColor(.flashOrange)
                        .fontWeight(.semibold)
                }
            }

            Spacer()

            // Match badges
            VStack(spacing: 4) {
                if job.greatMatch == true {
                    Text("Great Match")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
                if job.isHighPaying == true {
                    Text("High Pay")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.flashOrange.opacity(0.15))
                        .foregroundColor(.flashOrange)
                        .cornerRadius(4)
                }
            }
        }
        .padding(16)
    }

    private var tabContent: some View {
        VStack(spacing: 0) {
            // Segmented picker
            Picker("", selection: $selectedTab) {
                Text("Description").tag(0)
                Text("Requirements").tag(1)
                Text("Benefits").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch selectedTab {
                    case 0: descriptionTab
                    case 1: requirementsTab
                    default: benefitsTab
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 280)
        }
    }

    @ViewBuilder
    private var descriptionTab: some View {
        if let desc = job.jobDescription {
            Text(desc)
                .font(.callout)
                .foregroundColor(.primary)
        }
        if let categories = job.jobCategories, !categories.isEmpty {
            chipRow(label: "Categories", chips: categories, color: .flashNavy)
        }
        if let skills = job.desiredSkillsTags, !skills.isEmpty {
            chipRow(label: "Skills", chips: skills, color: .flashTeal)
        }
    }

    @ViewBuilder
    private var requirementsTab: some View {
        if let reqs = job.jobRequirements, !reqs.isEmpty {
            bulletList(items: reqs, label: "Requirements")
        }
        if let resps = job.jobResponsibilities, !resps.isEmpty {
            bulletList(items: resps, label: "Responsibilities")
        }
        if (job.jobRequirements?.isEmpty ?? true) && (job.jobResponsibilities?.isEmpty ?? true) {
            Text("No requirements listed.").foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var benefitsTab: some View {
        if let benefits = job.companyData?.benefits, !benefits.isEmpty {
            chipRow(label: "Benefits", chips: benefits, color: .green)
        } else {
            Text("No benefits listed.").foregroundColor(.secondary)
        }
        if let desc = job.companyData?.description {
            Text("About \(job.companyName ?? "the Company")")
                .font(.headline).foregroundColor(.flashNavy).padding(.top, 8)
            Text(desc).font(.callout)
        }
    }

    private func chipRow(label: String, chips: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            FlowLayout(items: chips) { chip in
                Text(chip)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .foregroundColor(color)
                    .cornerRadius(6)
            }
        }
    }

    private func bulletList(items: [String], label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.headline).foregroundColor(.flashNavy)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundColor(.flashTeal)
                    Text(item).font(.callout)
                }
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 40) {
            // Reject button
            Button(action: {
                withAnimation(.easeOut(duration: 0.3)) { dragOffset = CGSize(width: -600, height: 0) }
                Task { await onSwipe(false, [:]) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 64, height: 64)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            // Accept button
            Button(action: {
                if !(job.manualInputFields?.isEmpty ?? true) {
                    showManualAnswers = true
                } else {
                    withAnimation(.easeOut(duration: 0.3)) { dragOffset = CGSize(width: 600, height: 0) }
                    Task { await onSwipe(true, [:]) }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }) {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.flashTeal)
                    .frame(width: 64, height: 64)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.flashTeal.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

// MARK: - Simple Flow Layout for chips
struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geo.size.width {
                                width = 0; height -= d.height + 4
                            }
                            let result = width
                            if item == items.last { width = 0 } else { width -= d.width + 4 }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == items.last { height = 0 }
                            return result
                        }
                }
            }
        }
        .frame(height: max(CGFloat(items.count / 3 + 1) * 28, 28))
    }
}
