import Combine

protocol ObserveNewToBuyItemsUseCase {
    func execute() -> AnyPublisher<ToBuyItem, Never>
}

struct DefaultObserveNewToBuyItemsUseCase: ObserveNewToBuyItemsUseCase {
    let repository: ToBuyRepository

    func execute() -> AnyPublisher<ToBuyItem, Never> {
        repository.observeNewItems()
    }
}
