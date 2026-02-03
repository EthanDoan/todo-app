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
    private let observeItemsUseCase: ObserveToBuyItemsUseCase
    private var allItems: [ToBuyItem] = []
    private var cancellables = Set<AnyCancellable>()

    init(
        fetchItemsUseCase: FetchToBuyItemsUseCase,
        setWishlistUseCase: SetWishlistUseCase,
        observeItemsUseCase: ObserveToBuyItemsUseCase
    ) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.setWishlistUseCase = setWishlistUseCase
        self.observeItemsUseCase = observeItemsUseCase

        observeItemsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.allItems = items
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    func refreshItems() {
        isLoading = true
        let filter = ToBuyFilter(searchText: nil, maxPrice: nil)
        fetchItemsUseCase.execute(sort: .titleAscending, filter: filter)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] _ in
                self?.applyFilters()
            })
            .store(in: &cancellables)
    }

    func loadItems() {
        applyFilters()
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

    private func applyFilters() {
        let filtered = allItems.filter { shouldInclude($0) }
        items = sortedItems(filtered)
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
