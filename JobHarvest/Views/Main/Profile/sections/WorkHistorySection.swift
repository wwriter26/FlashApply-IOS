import SwiftUI

struct WorkHistorySection: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showAdd = false
    @State private var editingEntry: WorkHistoryEntry?

    var body: some View {
        List {
            ForEach(profileVM.profile.workHistory ?? []) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                    Text(entry.company)
                        .font(.caption).foregroundColor(.secondary)
                    HStack {
                        Text(entry.startDate ?? "")
                        if let end = entry.endDate { Text("– \(end)") }
                        else if entry.current == true { Text("– Present") }
                    }
                    .font(.caption).foregroundColor(.secondary)
                    if let loc = entry.location {
                        Text(loc).font(.caption).foregroundColor(.flashTextSecondary)
                    }
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
        .navigationTitle("Work History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus")
                }.foregroundColor(.flashTeal)
            }
        }
        .sheet(isPresented: $showAdd) {
            WorkHistoryEntryForm(entry: nil) { save(entry: $0) }
        }
        .sheet(item: $editingEntry) { entry in
            WorkHistoryEntryForm(entry: entry) { save(entry: $0, replacing: entry.id) }
        }
    }

    private func save(entry: WorkHistoryEntry, replacing id: String? = nil) {
        var updated = profileVM.profile
        var history = updated.workHistory ?? []
        if let id = id, let idx = history.firstIndex(where: { $0.id == id }) {
            history[idx] = entry
        } else {
            history.insert(entry, at: 0)
        }
        updated.workHistory = history
        Task { try? await profileVM.updateProfile(updated) }
    }

    private func deleteEntry(id: String) {
        var updated = profileVM.profile
        updated.workHistory?.removeAll { $0.id == id }
        Task { try? await profileVM.updateProfile(updated) }
    }
}

struct WorkHistoryEntryForm: View {
    let entry: WorkHistoryEntry?
    let onSave: (WorkHistoryEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var company = ""
    @State private var startDate = ""
    @State private var endDate = ""
    @State private var current = false
    @State private var description = ""
    @State private var location = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Job Title", text: $title)
                    TextField("Company", text: $company)
                    TextField("Location", text: $location)
                }
                Section("Dates") {
                    TextField("Start Date (e.g. Jan 2020)", text: $startDate)
                    if !current {
                        TextField("End Date (e.g. Dec 2022)", text: $endDate)
                    }
                    Toggle("Current Position", isOn: $current).tint(.flashTeal)
                }
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
            }
            .navigationTitle(entry == nil ? "Add Experience" : "Edit Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let e = WorkHistoryEntry(
                            company: company, title: title,
                            startDate: startDate.isEmpty ? nil : startDate,
                            endDate: current ? nil : (endDate.isEmpty ? nil : endDate),
                            current: current,
                            description: description.isEmpty ? nil : description,
                            location: location.isEmpty ? nil : location
                        )
                        onSave(e)
                        dismiss()
                    }
                    .foregroundColor(.flashTeal)
                    .disabled(title.isEmpty || company.isEmpty)
                }
            }
            .onAppear {
                if let e = entry {
                    title = e.title; company = e.company
                    startDate = e.startDate ?? ""; endDate = e.endDate ?? ""
                    current = e.current ?? false; description = e.description ?? ""
                    location = e.location ?? ""
                }
            }
        }
    }
}
