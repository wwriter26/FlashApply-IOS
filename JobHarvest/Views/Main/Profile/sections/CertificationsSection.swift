import SwiftUI

struct CertificationsSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showAdd = false

    var body: some View {
        List {
            ForEach(profileVM.profile.certifications ?? []) { cert in
                VStack(alignment: .leading, spacing: 4) {
                    Text(cert.name ?? "").font(.subheadline.weight(.semibold))
                    if let issuer = cert.issuer { Text(issuer).font(.caption).foregroundColor(.secondary) }
                    if let date = cert.date { Text(date).font(.caption).foregroundColor(.secondary) }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        var updated = profileVM.profile
                        updated.certifications?.removeAll { $0.id == cert.id }
                        Task { try? await profileVM.updateProfile(updated) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Certifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus")
                }.foregroundColor(.flashTeal)
            }
        }
        .sheet(isPresented: $showAdd) {
            CertificationForm { cert in
                var updated = profileVM.profile
                var list = updated.certifications ?? []
                list.append(cert)
                updated.certifications = list
                Task { try? await profileVM.updateProfile(updated) }
            }
        }
    }
}

struct CertificationForm: View {
    let onSave: (CertificationEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var issuer = ""
    @State private var date = ""
    @State private var url = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Certification Name", text: $name)
                TextField("Issuing Organization", text: $issuer)
                TextField("Date Earned", text: $date)
                TextField("Certificate URL (optional)", text: $url)
                    .keyboardType(.URL).autocapitalization(.none)
            }
            .navigationTitle("Add Certification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let c = CertificationEntry(name: name,
                                                    issuer: issuer.isEmpty ? nil : issuer,
                                                    date: date.isEmpty ? nil : date,
                                                    url: url.isEmpty ? nil : url)
                        onSave(c)
                        dismiss()
                    }
                    .foregroundColor(.flashTeal)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
