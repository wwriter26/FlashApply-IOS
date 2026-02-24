import SwiftUI
import Combine

struct EducationSection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showAdd = false
    @State private var editingEntry: EducationEntry?

    var body: some View {
        List {
            ForEach(profileVM.profile.education ?? []) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.institution).font(.subheadline.weight(.semibold))
                    if let degree = entry.degree { Text(degree).font(.caption).foregroundColor(.secondary) }
                    if let field = entry.field { Text(field).font(.caption).foregroundColor(.secondary) }
                    HStack {
                        Text(entry.startDate ?? "")
                        if let end = entry.endDate { Text("– \(end)") }
                        else if entry.current == true { Text("– Present") }
                    }
                    .font(.caption).foregroundColor(.secondary)
                    if let gpa = entry.gpa { Text("GPA: \(gpa)").font(.caption).foregroundColor(.flashTextSecondary) }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { deleteEntry(id: entry.id) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button { editingEntry = entry } label: {
                        Label("Edit", systemImage: "pencil")
                    }.tint(.flashTeal)
                }
            }
        }
        .navigationTitle("Education")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus")
                }.foregroundColor(.flashTeal)
            }
        }
        .sheet(isPresented: $showAdd) {
            EducationEntryForm(entry: nil) { save(entry: $0) }
        }
        .sheet(item: $editingEntry) { entry in
            EducationEntryForm(entry: entry) { save(entry: $0, replacing: entry.id) }
        }
    }

    private func save(entry: EducationEntry, replacing id: String? = nil) {
        var updated = profileVM.profile
        var edu = updated.education ?? []
        if let id = id, let idx = edu.firstIndex(where: { $0.id == id }) {
            edu[idx] = entry
        } else {
            edu.insert(entry, at: 0)
        }
        updated.education = edu
        Task { try? await profileVM.updateProfile(updated) }
    }

    private func deleteEntry(id: String) {
        var updated = profileVM.profile
        updated.education?.removeAll { $0.id == id }
        Task { try? await profileVM.updateProfile(updated) }
    }
}

struct EducationEntryForm: View {
    let entry: EducationEntry?
    let onSave: (EducationEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var institution = ""
    @State private var degree = ""
    @State private var field = ""
    @State private var startDate = ""
    @State private var endDate = ""
    @State private var current = false
    @State private var gpa = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Institution", text: $institution)
                    TextField("Degree (e.g. B.S.)", text: $degree)
                    TextField("Field of Study", text: $field)
                    TextField("GPA", text: $gpa).keyboardType(.decimalPad)
                }
                Section("Dates") {
                    TextField("Start Date (e.g. Aug 2018)", text: $startDate)
                    if !current { TextField("End Date (e.g. May 2022)", text: $endDate) }
                    Toggle("Currently Enrolled", isOn: $current).tint(.flashTeal)
                }
            }
            .navigationTitle(entry == nil ? "Add Education" : "Edit Education")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let e = EducationEntry(
                            institution: institution,
                            degree: degree.isEmpty ? nil : degree,
                            field: field.isEmpty ? nil : field,
                            startDate: startDate.isEmpty ? nil : startDate,
                            endDate: current ? nil : (endDate.isEmpty ? nil : endDate),
                            current: current,
                            gpa: gpa.isEmpty ? nil : gpa
                        )
                        onSave(e)
                        dismiss()
                    }
                    .foregroundColor(.flashTeal)
                    .disabled(institution.isEmpty)
                }
            }
            .onAppear {
                if let e = entry {
                    institution = e.institution; degree = e.degree ?? ""
                    field = e.field ?? ""; startDate = e.startDate ?? ""
                    endDate = e.endDate ?? ""; current = e.current ?? false
                    gpa = e.gpa ?? ""
                }
            }
        }
    }
}
