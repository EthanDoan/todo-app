import Foundation
import SwiftUI

struct ToSellView: View {
    @StateObject private var viewModel: ToSellViewModel
    @State private var editorMode: EditorMode?
    @State private var selection = Set<UUID>()
    @Environment(\.editMode) private var editMode

    init(viewModel: ToSellViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(viewModel.items) { item in
                Button {
                    guard editMode?.wrappedValue != .active else { return }
                    editorMode = .edit(item)
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.title)
                        HStack(spacing: 8) {
                            Text(currencyString(for: item.price))
                            if item.isSold {
                                Text("Sold")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: viewModel.delete)
        }
        .navigationTitle("To Sell")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                    editorMode = .add
                }
            }
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
            ToolbarItem(placement: .automatic) {
                Button("Undo") {
                    viewModel.undoDelete()
                }
                .disabled(!viewModel.canUndoDelete)
            }
            ToolbarItem(placement: .automatic) {
                Button("Delete Selected", role: .destructive) {
                    viewModel.bulkDelete(ids: Array(selection))
                    selection.removeAll()
                }
                .disabled(selection.isEmpty)
            }
        }
        .sheet(item: $editorMode) { mode in
            switch mode {
            case .add:
                ToSellItemEditorView(
                    title: "Add Item",
                    primaryActionTitle: "Save",
                    initialDraft: .init(title: "", priceText: "", isSold: false)
                ) { draft in
                    viewModel.addItem(title: draft.title, priceText: draft.priceText, isSold: draft.isSold)
                }
            case .edit(let item):
                ToSellItemEditorView(
                    title: "Edit Item",
                    primaryActionTitle: "Update",
                    initialDraft: .init(
                        title: item.title,
                        priceText: currencyText(for: item.price),
                        isSold: item.isSold
                    )
                ) { draft in
                    viewModel.updateItem(
                        id: item.id,
                        title: draft.title,
                        priceText: draft.priceText,
                        isSold: draft.isSold
                    )
                }
            }
        }
        .alert(
            "Validation Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private enum EditorMode: Identifiable {
    case add
    case edit(ToSellItem)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let item):
            return item.id.uuidString
        }
    }
}

private func currencyString(for price: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
}

private func currencyText(for price: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
}
