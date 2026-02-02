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
        apiClient.fetchItems(sort: sort, filter: filter)
    }

    func fetchDetail(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error> {
        apiClient.fetchDetail(id: id)
    }

    func setWishlist(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error> {
        wishlistStore.setWishlist(id: id, isWishlisted: isWishlisted)
    }

    func loadWishlist() -> AnyPublisher<[UUID], Error> {
        wishlistStore.loadWishlist()
    }
}
