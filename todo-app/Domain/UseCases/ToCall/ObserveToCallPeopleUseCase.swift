import Combine

protocol ObserveToCallPeopleUseCase {
    func execute() -> AnyPublisher<[ToCallPerson], Never>
}

struct DefaultObserveToCallPeopleUseCase: ObserveToCallPeopleUseCase {
    let repository: ToCallCacheRepository

    func execute() -> AnyPublisher<[ToCallPerson], Never> {
        repository.observePeople()
    }
}
