import SwiftUI

struct ToSellView: View {
    @StateObject private var viewModel: ToSellViewModel

    init(viewModel: ToSellViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List(selection: $viewModel.selection) {
            ForEach(viewModel.items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                    HStack {
                        Text("$\(item.price)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Toggle("Sold", isOn: Binding(
                            get: { item.isSold },
                            set: { viewModel.toggleSold(item: item, isSold: $0) }
                        ))
                        .labelsHidden()
                        Button {
                            viewModel.startEdit(item: item)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .swipeActions {
                    Button("Edit") {
                        viewModel.startEdit(item: item)
                    }
                    .tint(.blue)
                    Button(role: .destructive) {
                        viewModel.deleteItem(id: item.id)
                    } label: {
                        Text("Delete")
                    }
                }
            }
            .onDelete(perform: viewModel.delete)
        }
        .navigationTitle("To Sell")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") { viewModel.startAdd() }
            }
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Delete Selected") {
                    viewModel.bulkDeleteSelection()
                }
                .disabled(viewModel.selection.isEmpty)
            }
            ToolbarItem(placement: .automatic) {
                Button("Undo") { viewModel.undoDelete() }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingEditor) {
            ToSellEditorView(
                title: $viewModel.editorTitle,
                price: $viewModel.editorPrice,
                onSave: { viewModel.save() },
                onCancel: { viewModel.isPresentingEditor = false }
            )
        }
        .alert("Validation Error", isPresented: $viewModel.isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct ToSellEditorView: View {
    @Binding var title: String
    @Binding var price: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Title", text: $title)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
    }
}
