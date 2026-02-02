import Combine
import Foundation

final class WishlistStore {
    private var wishlist: Set<UUID> = []

    func loadWishlist() -> AnyPublisher<[UUID], Error> {
        Just(Array(wishlist))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func setWishlist(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error> {
        if isWishlisted {
            wishlist.insert(id)
        } else {
            wishlist.remove(id)
        }
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
