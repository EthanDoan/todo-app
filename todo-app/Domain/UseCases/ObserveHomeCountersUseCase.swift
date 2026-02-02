import Combine

protocol ObserveHomeCountersUseCase {
    func execute() -> AnyPublisher<HomeCounters, Never>
}

struct DefaultObserveHomeCountersUseCase: ObserveHomeCountersUseCase {
    let repository: HomeCounterRepository

    func execute() -> AnyPublisher<HomeCounters, Never> {
        repository.countersPublisher
    }
}
