import SwiftUI

struct FilterDrawerView: View {
    @Binding var filters: JobFilters
    let isPremium: Bool
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var postedAfterDays: Double = 0

    private let jobTypes = ["Internship", "Part-Time", "Full-Time", "Contract"]
    private let industries = [
        "Technology & Innovation",
        "Financial & Business Services",
        "Healthcare & Life Sciences",
        "Industrial/Trades/Manufacturing/Engineering",
        "Consumer & Retail",
        "Energy & Environmental Services",
        "Food & Agriculture",
        "Public Sector & Education",
        "Real Estate & Infrastructure",
        "Creative Industries",
        "Legal & Regulatory",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Company
                Section("Company") {
                    TextField("Company name", text: Binding(
                        get: { filters.companyKey ?? "" },
                        set: { filters.companyKey = $0.isEmpty ? nil : $0 }
                    ))
                }

                // Location
                Section("Location") {
                    TextField("State (e.g. CA)", text: Binding(
                        get: { filters.locationState ?? "" },
                        set: { filters.locationState = $0.isEmpty ? nil : $0 }
                    ))
                    .autocapitalization(.allCharacters)
                }

                // Industry
                Section("Job Industry") {
                    Picker("Industry", selection: Binding(
                        get: { filters.jobIndustry ?? "" },
                        set: { filters.jobIndustry = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Any").tag("")
                        ForEach(industries, id: \.self) { ind in
                            Text(ind).tag(ind)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Job Type
                Section("Job Type") {
                    ForEach(jobTypes, id: \.self) { type in
                        Toggle(type, isOn: Binding(
                            get: { filters.jobType?.contains(type) ?? false },
                            set: { isOn in
                                var types = filters.jobType ?? []
                                if isOn { types.append(type) } else { types.removeAll { $0 == type } }
                                filters.jobType = types.isEmpty ? nil : types
                            }
                        ))
                        .tint(.flashTeal)
                    }
                }

                // How New (Premium)
                Section {
                    if isPremium {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Posted Within")
                                Spacer()
                                Text(postedAfterDays == 0 ? "Any time" : "\(Int(postedAfterDays)) days")
                                    .foregroundColor(.flashTeal)
                                    .fontWeight(.semibold)
                            }
                            Slider(value: $postedAfterDays, in: 0...30, step: 1)
                                .tint(.flashTeal)
                        }
                    } else {
                        premiumLockRow(label: "How New (0–30 days)")
                    }
                } header: {
                    Label("How New", systemImage: "star.fill")
                        .foregroundColor(.flashOrange)
                }

                // Minimum Salary (Premium)
                Section {
                    if isPremium {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Minimum Salary")
                                Spacer()
                                Text(filters.minimumSalary.map { "$\(Int($0))k" } ?? "Any")
                                    .foregroundColor(.flashTeal)
                                    .fontWeight(.semibold)
                            }
                            Slider(value: Binding(
                                get: { filters.minimumSalary ?? 0 },
                                set: { filters.minimumSalary = $0 == 0 ? nil : $0 }
                            ), in: 0...250, step: 5)
                            .tint(.flashTeal)
                        }
                    } else {
                        premiumLockRow(label: "Minimum Salary ($0–$250k)")
                    }
                } header: {
                    Label("Minimum Salary", systemImage: "star.fill")
                        .foregroundColor(.flashOrange)
                }

                // Reset
                Section {
                    Button("Reset Filters", role: .destructive) {
                        filters = JobFilters()
                        postedAfterDays = 0
                    }
                }
            }
            .navigationTitle("Filter Jobs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if isPremium && postedAfterDays > 0 {
                            let cutoff = Date().addingTimeInterval(-postedAfterDays * 86400)
                            filters.postedAfterTimestamp = String(Int(cutoff.timeIntervalSince1970))
                        } else {
                            filters.postedAfterTimestamp = nil
                        }
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.flashTeal)
                }
            }
            .onAppear {
                if let ts = filters.postedAfterTimestamp, let epoch = Double(ts) {
                    let secondsAgo = Date().timeIntervalSince1970 - epoch
                    postedAfterDays = min(30, max(0, (secondsAgo / 86400).rounded()))
                }
            }
        }
    }

    private func premiumLockRow(label: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Image(systemName: "lock.fill")
                .foregroundColor(.secondary)
            NavigationLink(destination: PremiumView()) {
                Text("Upgrade")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.flashTeal)
            }
        }
    }
}
