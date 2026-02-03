import Combine
import Foundation

final class WishlistStore {
    private let userDefaults: UserDefaults
    private let storageKey = "wishlist.ids"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadWishlist() -> AnyPublisher<[UUID], Error> {
        Just(Array(loadWishlistSet()))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func setWishlist(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error> {
        var wishlist = loadWishlistSet()
        if isWishlisted {
            wishlist.insert(id)
        } else {
            wishlist.remove(id)
        }
        persistWishlist(wishlist)
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private func loadWishlistSet() -> Set<UUID> {
        guard let stored = userDefaults.array(forKey: storageKey) as? [String] else {
            return []
        }
        return Set(stored.compactMap(UUID.init))
    }

    private func persistWishlist(_ wishlist: Set<UUID>) {
        let stored = wishlist.map { $0.uuidString }
        userDefaults.set(stored, forKey: storageKey)
    }
}
