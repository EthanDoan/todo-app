import Combine

protocol ObserveToBuyItemsUseCase {
    func execute() -> AnyPublisher<[ToBuyItem], Never>
}

struct DefaultObserveToBuyItemsUseCase: ObserveToBuyItemsUseCase {
    let repository: ToBuyRepository

    func execute() -> AnyPublisher<[ToBuyItem], Never> {
        repository.observeItems()
    }
}
