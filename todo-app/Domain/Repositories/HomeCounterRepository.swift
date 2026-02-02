import Combine

protocol HomeCounterRepository {
    var countersPublisher: AnyPublisher<HomeCounters, Never> { get }
    func startRealtimeUpdates()
    func updateToCallCount(_ count: Int)
}
