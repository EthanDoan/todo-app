import SwiftUI

struct ToSellItemEditorView: View {
    struct Draft {
        var title: String
        var priceText: String
        var isSold: Bool
    }

    let title: String
    let primaryActionTitle: String
    let initialDraft: Draft
    let onSave: (Draft) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var draft: Draft

    init(title: String, primaryActionTitle: String, initialDraft: Draft, onSave: @escaping (Draft) -> Bool) {
        self.title = title
        self.primaryActionTitle = primaryActionTitle
        self.initialDraft = initialDraft
        self.onSave = onSave
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Title", text: $draft.title)
                    TextField("Price", text: $draft.priceText)
                        .keyboardType(.decimalPad)
                    Toggle("Sold", isOn: $draft.isSold)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryActionTitle) {
                        if onSave(draft) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ToSellItemEditorView(
        title: "Add Item",
        primaryActionTitle: "Save",
        initialDraft: .init(title: "", priceText: "", isSold: false),
        onSave: { _ in true }
    )
}
