import SwiftUI

struct PremiumView: View {
    @StateObject private var subscriptionVM = SubscriptionViewModel()
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var billingPeriod: BillingPeriod = .monthly
    @State private var showWebCheckout = false
    @State private var checkoutURL: URL?

    // Stripe return detection
    @Environment(\.scenePhase) private var scenePhase
    @State private var awaitingPaymentReturn = false
    @State private var isVerifyingPayment = false
    @State private var paymentResultMessage: String?
    @State private var paymentResultIsSuccess = false

    enum BillingPeriod { case monthly, seasonal, lifetime }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current plan banner
                    HStack(spacing: 12) {
                        Image(systemName: subscriptionVM.currentPlan == .free ? "person.circle.fill" : "crown.fill")
                            .font(.system(size: 24))
                            .foregroundColor(subscriptionVM.currentPlan == .free ? .flashTextSecondary : .flashTeal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Plan")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.flashTextSecondary)
                            Text("\(subscriptionVM.currentPlan.displayName) Plan")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.flashNavy)
                        }
                        Spacer()
                        Text("\(subscriptionVM.currentPlan.dailySwipes) swipes/day")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.flashTeal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.flashTeal.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(16)
                    .background(Color.flashWhite)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 42))
                            .foregroundColor(.flashTeal)
                        Text(subscriptionVM.currentPlan == .free ? "Upgrade JobHarvest" : "Manage Your Plan")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.flashNavy)
                        Text(subscriptionVM.currentPlan == .free ? "Apply to more jobs, faster" : "Switch plans anytime")
                            .foregroundColor(.secondary)
                    }

                    // Payment result banner
                    if let resultMessage = paymentResultMessage {
                        HStack(spacing: 12) {
                            Image(systemName: paymentResultIsSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(paymentResultIsSuccess ? Color(hex: "#00c97a") : Color(hex: "#e74c3c"))
                            Text(resultMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.flashDark)
                        }
                        .padding(14)
                        .background(paymentResultIsSuccess ? Color(hex: "#00c97a").opacity(0.10) : Color(hex: "#e74c3c").opacity(0.10))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                    }

                    // Billing Toggle
                    Picker("Billing", selection: $billingPeriod) {
                        Text("Monthly").tag(BillingPeriod.monthly)
                        Text("Seasonal").tag(BillingPeriod.seasonal)
                        Text("Lifetime").tag(BillingPeriod.lifetime)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 32)

                    if billingPeriod == .seasonal {
                        Text("Seasonal = 3-month plan, billed once. Best value!")
                            .font(.caption)
                            .foregroundColor(.flashTeal)
                            .fontWeight(.semibold)
                    }

                    // Plan Cards
                    VStack(spacing: 16) {
                        ForEach([SubscriptionPlan.plus, .pro], id: \.self) { plan in
                            PlanCard(
                                plan: plan,
                                billingPeriod: billingPeriod,
                                isCurrent: subscriptionVM.currentPlan == plan,
                                onSelect: { selectPlan(plan) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // Compliance note
                    VStack(spacing: 8) {
                        Divider()
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle").foregroundColor(.secondary)
                            Text("Subscriptions are managed at **jobharvest.com**. Tap a plan to open the secure checkout in your browser.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showWebCheckout) {
                if let url = checkoutURL {
                    SafariView(url: url)
                }
            }
            .alert("Error", isPresented: .constant(subscriptionVM.error != nil)) {
                Button("OK") { subscriptionVM.error = nil }
            } message: {
                Text(subscriptionVM.error ?? "")
            }
            .task {
                // Bridge plan from profileVM to subscriptionVM so the correct plan is shown
                if let planString = profileVM.profile.plan,
                   !planString.isEmpty,
                   let plan = SubscriptionPlan(rawValue: planString.lowercased()) {
                    subscriptionVM.currentPlan = plan
                }
            }
            .onChange(of: scenePhase) { newPhase in
                guard newPhase == .active, awaitingPaymentReturn else { return }
                awaitingPaymentReturn = false
                isVerifyingPayment = true
                Task {
                    await profileVM.fetchProfile()
                    if let planString = profileVM.profile.plan,
                       !planString.isEmpty,
                       let plan = SubscriptionPlan(rawValue: planString.lowercased()) {
                        subscriptionVM.currentPlan = plan
                        if plan != .free {
                            paymentResultMessage = "Plan updated! You're now on \(plan.displayName)."
                            paymentResultIsSuccess = true
                        } else {
                            paymentResultMessage = "Verification failed \u{2014} please contact support."
                            paymentResultIsSuccess = false
                        }
                    }
                    isVerifyingPayment = false
                    // Auto-dismiss success message after 3 seconds
                    if paymentResultIsSuccess {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        paymentResultMessage = nil
                    }
                }
            }
            .overlay {
                if isVerifyingPayment {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        LoadingView(message: "Verifying payment...")
                            .background(Color.flashWhite)
                            .cornerRadius(16)
                            .shadow(radius: 10)
                            .padding(40)
                    }
                }
            }
        }
    }

    private func selectPlan(_ plan: SubscriptionPlan) {
        Task {
            await subscriptionVM.createCheckoutSession(plan: plan)
            if let url = subscriptionVM.checkoutURL {
                checkoutURL = url
                awaitingPaymentReturn = true
                showWebCheckout = true
            }
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: SubscriptionPlan
    let billingPeriod: PremiumView.BillingPeriod
    let isCurrent: Bool
    let onSelect: () -> Void

    var price: String {
        switch billingPeriod {
        case .lifetime:
            return plan.lifetimePrice.map { "$\(Int($0))" } ?? "Free"
        case .seasonal:
            if let seasonal = plan.seasonalPrice {
                let perMonth = seasonal / 3.0
                return "$\(Int(seasonal)) (~$\(String(format: "%.0f", perMonth))/mo)"
            }
            return "Free"
        case .monthly:
            return plan.monthlyPrice.map { "$\(Int($0))/mo" } ?? "Free"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.flashNavy)
                        if plan == .plus {
                            Text("POPULAR")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.flashTeal)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    Text(price)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.flashTeal)
                    Text("\(plan.dailySwipes) swipes/day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isCurrent {
                    Text("Current Plan")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.flashTeal.opacity(0.15))
                        .foregroundColor(.flashTeal)
                        .cornerRadius(20)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.flashTeal)
                            .font(.caption)
                        Text(feature).font(.callout)
                    }
                }
            }

            if !isCurrent {
                Button(action: onSelect) {
                    Text("Choose \(plan.displayName)")
                }
                .primaryButtonStyle()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? Color.flashTeal : Color.clear, lineWidth: 2)
        )
    }
}
