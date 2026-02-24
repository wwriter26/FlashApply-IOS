import SwiftUI
import UIKit

struct EarnView: View {
    @StateObject private var referralVM = ReferralViewModel()
    @State private var showPayoutSheet = false
    @State private var payoutMethod = "PayPal"
    @State private var payoutEmail = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    earnHeader

                    // Stats
                    if let data = referralVM.referralData {
                        statsSection(data)
                        referralLinkSection
                        if data.referrals?.isEmpty == false {
                            referralListSection(data)
                        }
                        if referralVM.hasBalance {
                            payoutSection
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Earn & Referrals")
            .navigationBarTitleDisplayMode(.large)
            .task { if !referralVM.isLoaded { await referralVM.fetchReferralData() } }
            .refreshable { await referralVM.fetchReferralData() }
            .sheet(isPresented: $showPayoutSheet) { payoutSheet }
            .alert("Payout Requested!", isPresented: $referralVM.payoutSuccess) {
                Button("OK") {}
            }
        }
    }

    // MARK: - Header
    private var earnHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.system(size: 48)).foregroundColor(.flashTeal)
                .padding(.top, 16)
            Text("Refer & Earn")
                .font(.system(size: 24, weight: .bold)).foregroundColor(.flashNavy)
            Text("Earn cash rewards for every friend who upgrades to a paid plan.")
                .multilineTextAlignment(.center).foregroundColor(.secondary)
                .padding(.horizontal, 16)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Stats
    private func statsSection(_ data: ReferralData) -> some View {
        HStack(spacing: 16) {
            statCard(title: "Referrals", value: "\(data.totalReferrals ?? 0)", icon: "person.2.fill")
            statCard(title: "Total Earned", value: "$\(String(format: "%.2f", data.totalEarned ?? 0))", icon: "dollarsign.circle.fill")
            statCard(title: "Pending", value: "$\(String(format: "%.2f", data.pendingPayout ?? 0))", icon: "clock.fill")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.flashTeal).font(.title2)
            Text(value).font(.title3.weight(.bold)).foregroundColor(.flashNavy)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Referral Link
    private var referralLinkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Referral Link")
                .font(.headline).foregroundColor(.flashNavy)

            HStack {
                Text(referralVM.referralLink)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = referralVM.referralLink
                }) {
                    Image(systemName: "doc.on.doc").foregroundColor(.flashTeal)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)

            ShareLink(item: referralVM.referralLink) {
                Label("Share Link", systemImage: "square.and.arrow.up")
            }
            .primaryButtonStyle()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Referral List
    private func referralListSection(_ data: ReferralData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Referred Users (\(data.referrals?.count ?? 0))")
                .font(.headline).foregroundColor(.flashNavy)
            ForEach(data.referrals ?? []) { referral in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.flashTextSecondary).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(referral.name ?? referral.email ?? "User")
                            .font(.subheadline.weight(.medium))
                        Text(referral.plan?.capitalized ?? "Free Plan")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if let date = referral.joinedDate {
                        Text(date).font(.caption).foregroundColor(.secondary)
                    }
                }
                Divider()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Payout
    private var payoutSection: some View {
        VStack(spacing: 12) {
            Text("You have $\(String(format: "%.2f", referralVM.referralData?.pendingPayout ?? 0)) available")
                .font(.headline).foregroundColor(.flashNavy)
            Button(action: { showPayoutSheet = true }) {
                Text("Request Payout")
            }
            .primaryButtonStyle()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Payout Sheet
    private var payoutSheet: some View {
        NavigationStack {
            Form {
                Section("Payout Method") {
                    Picker("Method", selection: $payoutMethod) {
                        Text("PayPal").tag("PayPal")
                        Text("Venmo").tag("Venmo")
                        Text("Bank Transfer").tag("bank")
                    }
                }
                Section("Payment Details") {
                    TextField("Email or username", text: $payoutEmail)
                        .keyboardType(.emailAddress).autocapitalization(.none)
                }
            }
            .navigationTitle("Request Payout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showPayoutSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            await referralVM.requestPayout(
                                method: payoutMethod,
                                details: ["email": payoutEmail]
                            )
                            showPayoutSheet = false
                        }
                    }
                    .foregroundColor(.flashTeal)
                    .disabled(payoutEmail.isEmpty || referralVM.isLoading)
                }
            }
        }
    }
}
