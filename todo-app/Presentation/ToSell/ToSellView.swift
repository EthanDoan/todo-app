import SwiftUI

struct ToSellView: View {
    @StateObject private var viewModel: ToSellViewModel

    init(viewModel: ToSellViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                VStack(alignment: .leading) {
                    Text(item.title)
                    Text("$\(item.price)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete(perform: viewModel.delete)
        }
        .navigationTitle("To Sell")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                    viewModel.addSample()
                }
            }
            ToolbarItem(placement: .automatic) {
                Button("Undo") {
                    viewModel.undoDelete()
                }
            }
        }
    }
}
