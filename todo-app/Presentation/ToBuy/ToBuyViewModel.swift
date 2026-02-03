import Combine
import Foundation

final class ToBuyViewModel: ObservableObject {
    @Published private(set) var items: [ToBuyItem] = []
    @Published var sortOption: ToBuySortOption = .titleAscending
    @Published var searchText: String = ""
    @Published var maxPriceText: String = ""
    @Published private(set) var isLoading = false

    private let fetchItemsUseCase: FetchToBuyItemsUseCase
    private let setWishlistUseCase: SetWishlistUseCase
    private var cancellables = Set<AnyCancellable>()

    init(fetchItemsUseCase: FetchToBuyItemsUseCase, setWishlistUseCase: SetWishlistUseCase) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.setWishlistUseCase = setWishlistUseCase
    }

    func loadItems() {
        isLoading = true
        let filter = ToBuyFilter(searchText: normalizedSearchText(), maxPrice: parsedMaxPrice())
        fetchItemsUseCase.execute(sort: sortOption, filter: filter)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] items in
                self?.items = items
            })
            .store(in: &cancellables)
    }

    func toggleWishlist(for item: ToBuyItem) {
        let newValue = !item.isWishlisted
        setWishlistUseCase.execute(id: item.id, isWishlisted: newValue)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.items = self?.items.map { current in
                    guard current.id == item.id else { return current }
                    return ToBuyItem(id: current.id, title: current.title, price: current.price, isWishlisted: newValue)
                } ?? []
            })
            .store(in: &cancellables)
    }

    private func normalizedSearchText() -> String? {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func parsedMaxPrice() -> Decimal? {
        let trimmed = maxPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed)
    }
}
