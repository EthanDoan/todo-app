import Combine
import Foundation

final class HybridSyncRepository: SyncRepository {
    private let subject = CurrentValueSubject<[SellSyncItem], Never>([])

    var pendingSyncPublisher: AnyPublisher<[SellSyncItem], Never> {
        subject.eraseToAnyPublisher()
    }

    func markItemSold(id: UUID) throws {
        let newItem = SellSyncItem(id: UUID(), itemId: id, soldAt: Date(), syncedAt: nil)
        subject.send(subject.value + [newItem])
    }

    func performManualSync() -> AnyPublisher<Bool, Error> {
        Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func scheduleBackgroundSync() {
        // TODO: Integrate background task scheduler.
    }
}
