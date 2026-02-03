import SwiftUI

struct ToBuyDetailView: View {
    @StateObject private var viewModel: ToBuyDetailViewModel

    init(viewModel: ToBuyDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(detail.title)
                            .font(.title.bold())
                        Text("$\(detail.price)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(detail.description)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            } else if viewModel.isLoading {
                ProgressView("Loading...")
            } else {
                ContentUnavailableView("Item not found", systemImage: "cart.badge.questionmark")
            }
        }
        .navigationTitle("Item Detail")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.toggleWishlist() }) {
                    Image(systemName: (viewModel.detail?.isWishlisted ?? false) ? "heart.fill" : "heart")
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
    }
}

#Preview {
    let container = AppContainer()
    let viewModel = container.makeToBuyDetailViewModel(
        id: UUID(uuidString: "94A58B56-3D96-4F87-8B6B-1CC2A6D6F5ED") ?? UUID()
    )
    ToBuyDetailView(viewModel: viewModel)
}
