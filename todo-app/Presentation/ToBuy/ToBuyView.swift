import SwiftUI

struct ToBuyView: View {
    @StateObject private var viewModel: ToBuyViewModel
    private let detailViewModelBuilder: (UUID) -> ToBuyDetailViewModel

    init(viewModel: ToBuyViewModel, detailViewModelBuilder: @escaping (UUID) -> ToBuyDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.detailViewModelBuilder = detailViewModelBuilder
    }

    var body: some View {
        List {
            Section("Filters") {
                Picker("Sort by", selection: $viewModel.sortOption) {
                    ForEach(ToBuySortOption.allCases, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                }
                TextField("Max price", text: $viewModel.maxPriceText)
                    .keyboardType(.decimalPad)
            }

            Section("Items") {
                ForEach(viewModel.items) { item in
                    NavigationLink(destination: ToBuyDetailView(viewModel: detailViewModelBuilder(item.id))) {
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
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            if viewModel.items.isEmpty && !viewModel.isLoading {
                ContentUnavailableView("No matches", systemImage: "cart")
            }
        }
        .navigationTitle("To Buy")
        .searchable(text: $viewModel.searchText, prompt: "Search items")
        .onAppear {
            viewModel.loadItems()
        }
        .onChange(of: viewModel.sortOption, {
            viewModel.loadItems()
        })
        .onChange(of: viewModel.searchText, {
            viewModel.loadItems()
        })
        .onChange(of: viewModel.maxPriceText) {
            viewModel.loadItems()
        }
    }
}

#Preview {
    let container = AppContainer()
    ToBuyView(
        viewModel: container.makeToBuyViewModel(),
        detailViewModelBuilder: container.makeToBuyDetailViewModel
    )
}
