import Combine

protocol ObserveToSellItemsUseCase {
    func execute() -> AnyPublisher<[ToSellItem], Never>
}

struct DefaultObserveToSellItemsUseCase: ObserveToSellItemsUseCase {
    let repository: ToSellRepository

    func execute() -> AnyPublisher<[ToSellItem], Never> {
        repository.itemsPublisher
    }
}
