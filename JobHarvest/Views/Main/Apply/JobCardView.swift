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
                    .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 640)
        .background(Color.flashWhite)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
        .shadow(color: Color.flashTeal.opacity(0.06), radius: 24, x: 0, y: 12)
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

    // MARK: - Swipe Overlay
    private var swipeOverlay: some View {
        ZStack {
            // Accept overlay
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#00c97a").opacity(0.55), Color(hex: "#00c97a").opacity(0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(hex: "#00c97a").opacity(0.7), lineWidth: 2.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(hex: "#00c97a").opacity(0.6), radius: 12)
                        Text("APPLY")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color(hex: "#00c97a").opacity(0.5), radius: 8)
                    }
                    .padding(.leading, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
                .opacity(dragOffset.width > 20 ? min(Double(dragOffset.width - 20) / 80, 1.0) : 0)

            // Reject overlay
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#e74c3c").opacity(0.0), Color(hex: "#e74c3c").opacity(0.55)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(hex: "#e74c3c").opacity(0.7), lineWidth: 2.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    HStack(spacing: 10) {
                        Text("SKIP")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color(hex: "#e74c3c").opacity(0.5), radius: 8)
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(hex: "#e74c3c").opacity(0.6), radius: 12)
                    }
                    .padding(.trailing, 28)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                )
                .opacity(dragOffset.width < -20 ? min(Double(-dragOffset.width - 20) / 80, 1.0) : 0)
        }
    }

    // MARK: - Card Content
    private var cardContent: some View {
        VStack(spacing: 0) {
            cardHeader
            tabBar
            tabContent
            // Subtle brand watermark at the base of the card content area
            Image("jobHarvestTransparent")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .opacity(0.12)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Card Header
    private var cardHeader: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color.flashTeal, Color.flashNavy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 80)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24,
                    style: .continuous
                )
            )

            HStack(alignment: .top, spacing: 14) {
                CompanyLogoView(domain: job.companyData?.logoDomain ?? job.companyId, size: 60)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white, lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 4)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 3) {
                    Spacer().frame(height: 56)

                    Text(job.jobTitle ?? "Job Title")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.flashNavy)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(job.companyName ?? "Company")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.flashTextSecondary)
                        .padding(.top, 6)

                    HStack(spacing: 8) {
                        if let loc = job.jobLocation {
                            HStack(spacing: 3) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.flashTeal)
                                Text(loc)
                                    .font(.system(size: 12))
                                    .foregroundColor(.flashTextSecondary)
                            }
                        }
                        if let type = job.jobType {
                            Text(type)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.flashTeal.opacity(0.12))
                                .foregroundColor(.flashTeal)
                                .clipShape(Capsule())
                        }
                    }

                    if let pay = job.payEstimate {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.flashOrange)
                            Text(pay.formattedString)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.flashOrange)
                        }
                        .padding(.top, 1)
                    }
                }

                Spacer()

                VStack(spacing: 6) {
                    Spacer().frame(height: 52)
                    if job.greatMatch == true {
                        matchBadge(
                            text: "Great Match",
                            icon: "star.fill",
                            foreground: .white,
                            background: Color(hex: "#00c97a")
                        )
                    }
                    if job.isHighPaying == true {
                        matchBadge(
                            text: "High Pay",
                            icon: "arrow.up.circle.fill",
                            foreground: .white,
                            background: Color.flashOrange
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
    }

    private func matchBadge(text: String, icon: String, foreground: Color, background: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(text)
                .font(.system(size: 9, weight: .bold))
                .kerning(0.3)
        }
        .foregroundColor(foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(background)
        .clipShape(Capsule())
        .shadow(color: background.opacity(0.4), radius: 4, x: 0, y: 2)
    }

    // MARK: - Custom Tab Bar
    private var tabBar: some View {
        let tabs = ["Description", "Requirements", "Benefits"]
        return HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tabs[index])
                            .font(.system(size: 13, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? .flashNavy : .flashTextSecondary)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)

                        Capsule()
                            .fill(selectedTab == index ? Color.flashTeal : Color.clear)
                            .frame(height: 2.5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.flashWhite)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Tab Content
    private var tabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                switch selectedTab {
                case 0: descriptionTab
                case 1: requirementsTab
                default: benefitsTab
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxHeight: 360)
    }

    @ViewBuilder
    private var descriptionTab: some View {
        if let desc = job.jobDescription {
            Text(desc)
                .font(.system(size: 14))
                .foregroundColor(Color.flashDark)
                .lineSpacing(4)
        }
        if let categories = job.jobCategories, !categories.isEmpty {
            chipRow(label: "CATEGORIES", chips: categories, color: .flashNavy)
        }
        if let skills = job.desiredSkillsTags, !skills.isEmpty {
            chipRow(label: "SKILLS", chips: skills, color: .flashTeal)
        }
    }

    @ViewBuilder
    private var requirementsTab: some View {
        if let reqs = job.jobRequirements, !reqs.isEmpty {
            bulletList(items: reqs, label: "REQUIREMENTS")
        }
        if let resps = job.jobResponsibilities, !resps.isEmpty {
            bulletList(items: resps, label: "RESPONSIBILITIES")
        }
        if (job.jobRequirements?.isEmpty ?? true) && (job.jobResponsibilities?.isEmpty ?? true) {
            placeholderMessage(icon: "list.bullet.clipboard", text: "No requirements listed.")
        }
    }

    @ViewBuilder
    private var benefitsTab: some View {
        if let benefits = job.companyData?.benefits, !benefits.isEmpty {
            chipRow(label: "BENEFITS", chips: benefits, color: Color(hex: "#00c97a"))
        } else {
            placeholderMessage(icon: "gift", text: "No benefits listed.")
        }
        if let desc = job.companyData?.description {
            sectionLabel("ABOUT \(job.companyName?.uppercased() ?? "THE COMPANY")")
            Text(desc)
                .font(.system(size: 14))
                .foregroundColor(Color.flashDark)
                .lineSpacing(4)
        }
    }

    // MARK: - Content Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .kerning(0.8)
            .foregroundColor(.flashTextSecondary)
    }

    private func chipRow(label: String, chips: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(label)
            FlowLayout(items: chips) { chip in
                Text(chip)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.10))
                    .foregroundColor(color)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.25), lineWidth: 1)
                    )
            }
        }
    }

    private func bulletList(items: [String], label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(label)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.flashTeal)
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundColor(Color.flashDark)
                        .lineSpacing(3)
                }
            }
        }
    }

    private func placeholderMessage(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.flashTextSecondary)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.flashTextSecondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 44) {
            // Reject button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeOut(duration: 0.3)) { dragOffset = CGSize(width: -600, height: 0) }
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await onSwipe(false, [:])
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#e74c3c").opacity(0.15))
                        .frame(width: 76, height: 76)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color(hex: "#fff5f5")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color(hex: "#e74c3c").opacity(0.30), radius: 10, x: 0, y: 5)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#e74c3c").opacity(0.20), lineWidth: 1.5)
                                .frame(width: 64, height: 64)
                        )

                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "#e74c3c"))
                }
            }

            // Accept button
            Button(action: {
                if !(job.manualInputFields?.isEmpty ?? true) {
                    showManualAnswers = true
                } else {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.easeOut(duration: 0.3)) { dragOffset = CGSize(width: 600, height: 0) }
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await onSwipe(true, [:])
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.flashTeal.opacity(0.15))
                        .frame(width: 76, height: 76)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.flashTeal, Color.flashTealDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.flashTeal.opacity(0.45), radius: 12, x: 0, y: 6)

                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
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
