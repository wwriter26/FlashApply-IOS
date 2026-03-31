import SwiftUI
import os

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current plan banner
                    HStack(spacing: 12) {
                        Image("jobHarvestTransparent")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Plan")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.flashTextSecondary)
                            Text(subscriptionVM.currentPlan.displayName)
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
                        Image("jobHarvestTransparent")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
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

                    // Plan Cards — one for Plus, one for Pro
                    VStack(spacing: 16) {
                        ForEach(SubscriptionTier.allCases) { tier in
                            let fullPlan = SubscriptionPlan.from(tier: tier, period: billingPeriod)
                            PlanCard(
                                tier: tier,
                                plan: fullPlan,
                                isCurrent: subscriptionVM.currentPlan.tier == tier,
                                onSelect: { selectPlan(fullPlan) }
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
                if let planString = profileVM.profile.plan, !planString.isEmpty {
                    subscriptionVM.currentPlan = SubscriptionPlan.fromBackend(planString)
                }
            }
            .onChange(of: scenePhase) { newPhase in
                guard newPhase == .active, awaitingPaymentReturn else { return }
                awaitingPaymentReturn = false
                isVerifyingPayment = true
                Task {
                    await profileVM.fetchProfile()
                    if let planString = profileVM.profile.plan, !planString.isEmpty {
                        let plan = SubscriptionPlan.fromBackend(planString)
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
                    if paymentResultIsSuccess {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        paymentResultMessage = nil
                    }
                }
            }
            .overlay {
                // Show a blocking overlay during the API call to createCheckoutSession
                // and again during post-payment profile verification.
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

    // MARK: - Checkout

    private func selectPlan(_ plan: SubscriptionPlan) {
        let urlString = "https://jobharvest.com/dashboard/premium"
        AppLogger.subscription.info("selectPlan: opening \(urlString)")
        if let url = URL(string: urlString) {
            awaitingPaymentReturn = true
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let tier: SubscriptionTier
    let plan: SubscriptionPlan
    let isCurrent: Bool
    let onSelect: () -> Void

    var priceText: String {
        let p = plan.price
        if p == 0 { return "Free" }
        switch plan.billingPeriod {
        case .monthly:
            return "$\(Int(p))/mo"
        case .seasonal:
            let perMonth = p / 3.0
            return "$\(Int(p)) (~$\(String(format: "%.0f", perMonth))/mo)"
        case .lifetime:
            return "$\(Int(p)) one-time"
        case .none:
            return "Free"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tier.displayName)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.flashNavy)
                        if tier == .plus {
                            Text("POPULAR")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.flashTeal)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    Text(priceText)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.flashTeal)
                    Text("\(tier.dailySwipes) swipes/day")
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
                ForEach(tier.features, id: \.self) { feature in
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
                    Text("Choose \(tier.displayName)")
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
