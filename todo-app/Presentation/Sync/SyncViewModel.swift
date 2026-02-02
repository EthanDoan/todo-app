import Combine
import Foundation

final class SyncViewModel: ObservableObject {
    @Published private(set) var pendingItems: [SellSyncItem] = []

    private let observePendingUseCase: ObservePendingSyncUseCase
    private let manualSyncUseCase: PerformManualSyncUseCase
    private var cancellables = Set<AnyCancellable>()

    init(observePendingUseCase: ObservePendingSyncUseCase, manualSyncUseCase: PerformManualSyncUseCase) {
        self.observePendingUseCase = observePendingUseCase
        self.manualSyncUseCase = manualSyncUseCase
        bind()
    }

    private func bind() {
        observePendingUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.pendingItems = items
            }
            .store(in: &cancellables)
    }

    func syncNow() {
        manualSyncUseCase.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
