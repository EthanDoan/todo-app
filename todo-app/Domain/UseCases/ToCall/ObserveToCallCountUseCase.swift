import Combine

protocol ObserveToCallCountUseCase {
    func execute() -> AnyPublisher<Int, Never>
}

struct DefaultObserveToCallCountUseCase: ObserveToCallCountUseCase {
    let repository: ToCallRepository

    func execute() -> AnyPublisher<Int, Never> {
        repository.observeCount()
    }
}
