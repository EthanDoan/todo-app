import Combine
import Foundation

final class HybridSyncRepository: SyncRepository {
    private let store = SQLiteSellSyncStore()
    private let subject = CurrentValueSubject<[SellSyncItem], Never>([])
    private var cancellables = Set<AnyCancellable>()
    private var backgroundSyncCancellable: AnyCancellable?

    init() {
        refreshPending()
    }

    var pendingSyncPublisher: AnyPublisher<[SellSyncItem], Never> {
        subject.eraseToAnyPublisher()
    }

    func markItemSold(id: UUID) throws {
        _ = try store.insertPending(itemId: id, soldAt: Date())
        refreshPending()
    }

    func performManualSync() -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            guard let self else { return }
            do {
                let pendingItems = try self.store.fetchPending()
                let ids = pendingItems.map(\.id)
                try self.store.markSynced(ids: ids, syncedDate: Date())
                self.refreshPending()
                promise(.success(true))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func scheduleBackgroundSync() {
        guard backgroundSyncCancellable == nil else { return }
        backgroundSyncCancellable = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.performManualSync()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self.cancellables)
            }
    }

    private func refreshPending() {
        do {
            subject.send(try store.fetchPending())
        } catch {
            subject.send([])
        }
    }
}
