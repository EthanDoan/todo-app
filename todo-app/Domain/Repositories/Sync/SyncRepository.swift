import Combine

protocol SyncRepository {
    var pendingSyncPublisher: AnyPublisher<[SellSyncItem], Never> { get }
    func markItemSold(id: UUID) throws
    func performManualSync() -> AnyPublisher<Bool, Error>
    func scheduleBackgroundSync()
}
