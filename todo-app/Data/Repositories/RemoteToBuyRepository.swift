import Combine
import Foundation

final class RemoteToBuyRepository: ToBuyRepository {
    private let apiClient: ToBuyAPIClient
    private let wishlistStore: WishlistStore
    private let store: InMemoryToBuyStore
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: ToBuyAPIClient, wishlistStore: WishlistStore, store: InMemoryToBuyStore) {
        self.apiClient = apiClient
        self.wishlistStore = wishlistStore
        self.store = store
        subscribeToRealtimeItems()
    }

    func fetchItems(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error> {
        Publishers.CombineLatest(
            apiClient.fetchItems(sort: sort, filter: filter),
            wishlistStore.loadWishlist()
        )
        .map { items, wishlist in
            let wishlistSet = Set(wishlist)
            return items.map { item in
                ToBuyItem(
                    id: item.id,
                    title: item.title,
                    price: item.price,
                    isWishlisted: wishlistSet.contains(item.id)
                )
            }
        }
        .handleEvents(receiveOutput: { [weak self] items in
            self?.store.updateItems(self?.mergedItems(items) ?? items)
        })
        .eraseToAnyPublisher()
    }

    func fetchDetail(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error> {
        Publishers.CombineLatest(
            apiClient.fetchDetail(id: id),
            wishlistStore.loadWishlist()
        )
        .map { detail, wishlist in
            ToBuyItemDetail(
                id: detail.id,
                title: detail.title,
                description: detail.description,
                price: detail.price,
                isWishlisted: wishlist.contains(detail.id)
            )
        }
        .eraseToAnyPublisher()
    }

    func setWishlist(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error> {
        wishlistStore.setWishlist(id: id, isWishlisted: isWishlisted)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.store.updateWishlist(id: id, isWishlisted: isWishlisted)
            })
            .eraseToAnyPublisher()
    }

    func loadWishlist() -> AnyPublisher<[UUID], Error> {
        wishlistStore.loadWishlist()
    }

    func observeItems() -> AnyPublisher<[ToBuyItem], Never> {
        store.itemsPublisher
    }

    private func subscribeToRealtimeItems() {
        apiClient.observeNewItems()
            .sink { [weak self] item in
                self?.store.appendItem(item)
            }
            .store(in: &cancellables)
    }

    private func mergedItems(_ fetched: [ToBuyItem]) -> [ToBuyItem] {
        let fetchedIds = Set(fetched.map(\.id))
        let existing = store.currentItems().filter { !fetchedIds.contains($0.id) }
        return fetched + existing
    }
}
