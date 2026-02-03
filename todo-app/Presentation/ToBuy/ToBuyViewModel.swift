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
    private let updateToBuyCountUseCase: UpdateToBuyCountUseCase
    private let observeNewItemsUseCase: ObserveNewToBuyItemsUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        fetchItemsUseCase: FetchToBuyItemsUseCase,
        setWishlistUseCase: SetWishlistUseCase,
        updateToBuyCountUseCase: UpdateToBuyCountUseCase,
        observeNewItemsUseCase: ObserveNewToBuyItemsUseCase
    ) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.setWishlistUseCase = setWishlistUseCase
        self.updateToBuyCountUseCase = updateToBuyCountUseCase
        self.observeNewItemsUseCase = observeNewItemsUseCase

        observeNewItemsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                self?.handleIncomingItem(item)
            }
            .store(in: &cancellables)
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
                self?.updateToBuyCountUseCase.execute(count: items.count)
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

    private func handleIncomingItem(_ item: ToBuyItem) {
        guard shouldInclude(item) else { return }
        items.append(item)
        items = sortedItems(items)
    }

    private func shouldInclude(_ item: ToBuyItem) -> Bool {
        if let searchText = normalizedSearchText()?.lowercased() {
            guard item.title.lowercased().contains(searchText) else { return false }
        }

        if let maxPrice = parsedMaxPrice() {
            guard item.price <= maxPrice else { return false }
        }

        return true
    }

    private func sortedItems(_ items: [ToBuyItem]) -> [ToBuyItem] {
        switch sortOption {
        case .priceAscending:
            return items.sorted { $0.price < $1.price }
        case .priceDescending:
            return items.sorted { $0.price > $1.price }
        case .titleAscending:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}
