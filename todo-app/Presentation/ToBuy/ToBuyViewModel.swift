import Combine
import Foundation

final class ToBuyViewModel: ObservableObject {
    @Published private(set) var items: [ToBuyItem] = []

    private let fetchItemsUseCase: FetchToBuyItemsUseCase
    private let setWishlistUseCase: SetWishlistUseCase
    private var cancellables = Set<AnyCancellable>()

    init(fetchItemsUseCase: FetchToBuyItemsUseCase, setWishlistUseCase: SetWishlistUseCase) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.setWishlistUseCase = setWishlistUseCase
    }

    func loadItems() {
        fetchItemsUseCase.execute(sort: .titleAscending, filter: ToBuyFilter(searchText: nil, maxPrice: nil))
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] items in
                self?.items = items
            })
            .store(in: &cancellables)
    }

    func toggleWishlist(for item: ToBuyItem) {
        setWishlistUseCase.execute(id: item.id, isWishlisted: !item.isWishlisted)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
