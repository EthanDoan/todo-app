import Combine
import Foundation

final class ToBuyAPIClient {
    func fetchItems(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error> {
        Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }

    func fetchDetail(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error> {
        Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
}
