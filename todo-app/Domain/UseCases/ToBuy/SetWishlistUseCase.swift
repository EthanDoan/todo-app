import Combine
import Foundation

protocol SetWishlistUseCase {
    func execute(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error>
}

struct DefaultSetWishlistUseCase: SetWishlistUseCase {
    let repository: ToBuyRepository

    func execute(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error> {
        repository.setWishlist(id: id, isWishlisted: isWishlisted)
    }
}
