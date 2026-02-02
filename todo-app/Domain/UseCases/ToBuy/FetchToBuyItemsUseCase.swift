import Combine

protocol FetchToBuyItemsUseCase {
    func execute(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error>
}

struct DefaultFetchToBuyItemsUseCase: FetchToBuyItemsUseCase {
    let repository: ToBuyRepository

    func execute(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error> {
        repository.fetchItems(sort: sort, filter: filter)
    }
}
