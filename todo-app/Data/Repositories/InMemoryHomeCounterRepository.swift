import Combine
import Foundation

final class InMemoryHomeCounterRepository: HomeCounterRepository {
    private let subject = CurrentValueSubject<HomeCounters, Never>(.zero)
    private var timerCancellable: AnyCancellable?

    var countersPublisher: AnyPublisher<HomeCounters, Never> {
        subject.eraseToAnyPublisher()
    }

    func startRealtimeUpdates() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.incrementCounters()
            }
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

    private func incrementCounters() {
        let current = subject.value
        let updated = HomeCounters(
            toCall: current.toCall,
            toBuy: current.toBuy + 2,
            toSell: current.toSell + 1,
            sync: current.sync + 1
        )
        subject.send(updated)
    }
}
