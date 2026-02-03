import Combine
import Foundation

protocol ToBuyRepository {
    func fetchItems(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error>
    func fetchDetail(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error>
    func setWishlist(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error>
    func loadWishlist() -> AnyPublisher<[UUID], Error>
    func observeNewItems() -> AnyPublisher<ToBuyItem, Never>
}
