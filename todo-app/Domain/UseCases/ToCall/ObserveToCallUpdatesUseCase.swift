import Combine

protocol ObserveToCallUpdatesUseCase {
    func execute() -> AnyPublisher<[ToCallPerson], Never>
}

struct DefaultObserveToCallUpdatesUseCase: ObserveToCallUpdatesUseCase {
    let repository: ToCallRepository

    func execute() -> AnyPublisher<[ToCallPerson], Never> {
        repository.observeUpdates()
    }
}
