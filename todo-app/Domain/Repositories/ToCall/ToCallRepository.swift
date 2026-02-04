import Combine

protocol ToCallRepository {
    func fetchPeople(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error>
    func retryLastRequest() -> AnyPublisher<ToCallPage, Error>
    func observeUpdates() -> AnyPublisher<[ToCallPerson], Never>
}
