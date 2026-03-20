import SwiftUI

struct ManualAnswersSheet: View {
    let fields: [ManualInputField]
    let onSubmit: ([String: String]) -> Void

    @State private var answers: [String: String] = [:]
    @Environment(\.dismiss) private var dismiss

    // Use fieldKey if available, fall back to classification (backend sends either)
    private func key(for field: ManualInputField) -> String {
        field.fieldKey ?? field.classification ?? field.id
    }

    // Use fieldLabel if available, fall back to label
    private func displayLabel(for field: ManualInputField) -> String {
        field.fieldLabel ?? field.label ?? "Question"
    }

    // Use options or selectOptions
    private func allOptions(for field: ManualInputField) -> [String]? {
        field.options ?? field.selectOptions
    }

    var allRequiredFilled: Bool {
        fields.filter { $0.required == true }.allSatisfy { !(answers[key(for: $0)]?.isEmpty ?? true) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("This job requires additional information to complete your application.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }

                Section("Application Questions") {
                    ForEach(fields) { field in
                        fieldView(field)
                    }
                }
            }
            .navigationTitle("Additional Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit Application") {
                        onSubmit(answers)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.flashTeal)
                    .disabled(!allRequiredFilled)
                }
            }
        }
    }

    @ViewBuilder
    private func fieldView(_ field: ManualInputField) -> some View {
        let fieldId = key(for: field)
        let label = displayLabel(for: field)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                if field.required == true {
                    Text("*").foregroundColor(.red)
                }
            }

            switch field.fieldType {
            case "select":
                if let options = allOptions(for: field) {
                    Picker(label, selection: Binding(
                        get: { answers[fieldId] ?? "" },
                        set: { answers[fieldId] = $0 }
                    )) {
                        Text("Select...").tag("")
                        ForEach(options, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                }

            case "boolean":
                Toggle("Yes", isOn: Binding(
                    get: { answers[fieldId] == "true" },
                    set: { answers[fieldId] = $0 ? "true" : "false" }
                ))
                .tint(.flashTeal)

            case "textarea":
                TextEditor(text: Binding(
                    get: { answers[fieldId] ?? "" },
                    set: { answers[fieldId] = $0 }
                ))
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

            default: // "text" or nil
                TextField("Enter answer...", text: Binding(
                    get: { answers[fieldId] ?? "" },
                    set: { answers[fieldId] = $0 }
                ))
            }
        }
    }
}
