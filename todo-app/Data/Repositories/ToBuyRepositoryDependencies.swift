import Combine
import Foundation

protocol ToBuyAPIClientProtocol {
    func fetchItems(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error>
    func fetchDetail(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error>
    func observeNewItems() -> AnyPublisher<ToBuyItem, Never>
}

protocol WishlistStoreProtocol {
    func loadWishlist() -> AnyPublisher<[UUID], Error>
    func setWishlist(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error>
}

extension ToBuyAPIClient: ToBuyAPIClientProtocol {}
extension WishlistStore: WishlistStoreProtocol {}
