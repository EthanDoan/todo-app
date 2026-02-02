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

    private func incrementCounters() {
        let current = subject.value
        let updated = HomeCounters(
            toCall: current.toCall + 1,
            toBuy: current.toBuy + 2,
            toSell: current.toSell + 1,
            sync: current.sync + 1
        )
        subject.send(updated)
    }
}
