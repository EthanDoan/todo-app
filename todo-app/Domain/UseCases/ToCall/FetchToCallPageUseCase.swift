import Combine

protocol FetchToCallPageUseCase {
    func execute(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error>
}

struct DefaultFetchToCallPageUseCase: FetchToCallPageUseCase {
    let repository: ToCallRepository

    func execute(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error> {
        repository.fetchPeople(page: page, filter: filter)
    }
}
