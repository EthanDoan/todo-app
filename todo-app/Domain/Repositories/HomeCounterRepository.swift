import Combine

protocol HomeCounterRepository {
    var countersPublisher: AnyPublisher<HomeCounters, Never> { get }
    func updateToCallCount(_ count: Int)
    func updateToBuyCount(_ count: Int)
    func updateToSellCount(_ count: Int)
}
