import Combine

protocol HomeCounterRepository {
    var countersPublisher: AnyPublisher<HomeCounters, Never> { get }
    func updateToCallCount(_ count: Int)
}
