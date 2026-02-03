import Combine
import Foundation

final class InMemoryToBuyStore {
    private let subject = CurrentValueSubject<[ToBuyItem], Never>([])

    var itemsPublisher: AnyPublisher<[ToBuyItem], Never> {
        subject.eraseToAnyPublisher()
    }

    func updateItems(_ items: [ToBuyItem]) {
        subject.send(items)
    }

    func appendItem(_ item: ToBuyItem) {
        var current = subject.value
        current.append(item)
        subject.send(current)
    }

    func updateWishlist(id: UUID, isWishlisted: Bool) {
        let updated = subject.value.map { item in
            guard item.id == id else { return item }
            return ToBuyItem(
                id: item.id,
                title: item.title,
                price: item.price,
                isWishlisted: isWishlisted
            )
        }
        subject.send(updated)
    }

    func currentItems() -> [ToBuyItem] {
        subject.value
    }
}
