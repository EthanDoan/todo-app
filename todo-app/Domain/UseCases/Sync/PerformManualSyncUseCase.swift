import Combine

protocol PerformManualSyncUseCase {
    func execute() -> AnyPublisher<Bool, Error>
}

struct DefaultPerformManualSyncUseCase: PerformManualSyncUseCase {
    let repository: SyncRepository

    func execute() -> AnyPublisher<Bool, Error> {
        repository.performManualSync()
    }
}
