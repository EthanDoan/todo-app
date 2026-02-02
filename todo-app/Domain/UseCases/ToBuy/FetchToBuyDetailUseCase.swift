import Combine
import Foundation

protocol FetchToBuyDetailUseCase {
    func execute(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error>
}

struct DefaultFetchToBuyDetailUseCase: FetchToBuyDetailUseCase {
    let repository: ToBuyRepository

    func execute(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error> {
        repository.fetchDetail(id: id)
    }
}
