import Combine
import Foundation

final class RemoteToBuyRepository: ToBuyRepository {
    private let apiClient: ToBuyAPIClient
    private let wishlistStore: WishlistStore

    init(apiClient: ToBuyAPIClient, wishlistStore: WishlistStore) {
        self.apiClient = apiClient
        self.wishlistStore = wishlistStore
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
    }

    func loadWishlist() -> AnyPublisher<[UUID], Error> {
        wishlistStore.loadWishlist()
    }

    func observeNewItems() -> AnyPublisher<ToBuyItem, Never> {
        apiClient.observeNewItems()
            .map { item in
                ToBuyItem(
                    id: item.id,
                    title: item.title,
                    price: item.price,
                    isWishlisted: false
                )
            }
            .eraseToAnyPublisher()
    }
}
