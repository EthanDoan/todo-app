import Combine
import Foundation

final class InMemoryHomeCounterRepository: HomeCounterRepository {
    private let subject = CurrentValueSubject<HomeCounters, Never>(.zero)
    private var timerCancellable: AnyCancellable?

    var countersPublisher: AnyPublisher<HomeCounters, Never> {
        subject.eraseToAnyPublisher()
    }

    func updateToCallCount(_ count: Int) {
        let current = subject.value
        let updated = HomeCounters(
            toCall: count,
            toBuy: current.toBuy,
            toSell: current.toSell,
            sync: current.sync
        )
        subject.send(updated)
    }

    func updateToBuyCount(_ count: Int) {
        let current = subject.value
        let updated = HomeCounters(
            toCall: current.toCall,
            toBuy: count,
            toSell: current.toSell,
            sync: current.sync
        )
        subject.send(updated)
    }
}
