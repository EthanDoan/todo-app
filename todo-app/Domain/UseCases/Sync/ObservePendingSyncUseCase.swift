import Combine

protocol ObservePendingSyncUseCase {
    func execute() -> AnyPublisher<[SellSyncItem], Never>
}

struct DefaultObservePendingSyncUseCase: ObservePendingSyncUseCase {
    let repository: SyncRepository

    func execute() -> AnyPublisher<[SellSyncItem], Never> {
        repository.pendingSyncPublisher
    }
}
