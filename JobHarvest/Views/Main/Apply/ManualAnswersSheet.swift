import SwiftUI

struct ManualAnswersSheet: View {
    let fields: [ManualInputField]
    let onSubmit: ([String: String]) -> Void

    @State private var answers: [String: String] = [:]
    @Environment(\.dismiss) private var dismiss

    var allRequiredFilled: Bool {
        fields.filter { $0.required == true }.allSatisfy { !(answers[$0.fieldKey]?.isEmpty ?? true) }
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(field.fieldLabel)
                    .font(.subheadline.weight(.medium))
                if field.required == true {
                    Text("*").foregroundColor(.red)
                }
            }

            switch field.fieldType {
            case "select":
                if let options = field.options {
                    Picker(field.fieldLabel, selection: Binding(
                        get: { answers[field.fieldKey] ?? "" },
                        set: { answers[field.fieldKey] = $0 }
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
                    get: { answers[field.fieldKey] == "true" },
                    set: { answers[field.fieldKey] = $0 ? "true" : "false" }
                ))
                .tint(.flashTeal)

            case "textarea":
                TextEditor(text: Binding(
                    get: { answers[field.fieldKey] ?? "" },
                    set: { answers[field.fieldKey] = $0 }
                ))
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

            default: // "text"
                TextField("Enter answer...", text: Binding(
                    get: { answers[field.fieldKey] ?? "" },
                    set: { answers[field.fieldKey] = $0 }
                ))
            }
        }
    }
}
