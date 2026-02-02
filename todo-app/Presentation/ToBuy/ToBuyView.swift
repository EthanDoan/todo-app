import SwiftUI

struct ToBuyView: View {
    @StateObject private var viewModel: ToBuyViewModel

    init(viewModel: ToBuyViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text("$\(item.price)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: { viewModel.toggleWishlist(for: item) }) {
                        Image(systemName: item.isWishlisted ? "heart.fill" : "heart")
                    }
                }
            }
        }
        .navigationTitle("To Buy")
        .onAppear {
            viewModel.loadItems()
        }
    }
}
