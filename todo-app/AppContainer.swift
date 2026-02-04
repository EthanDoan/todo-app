import Combine
import Foundation

final class AppContainer {
    private let counterRepository: HomeCounterRepository
    private let observeCountersUseCase: ObserveHomeCountersUseCase
    private let startUpdatesUseCase: StartHomeCountersUpdatesUseCase

    private let toCallRepository: ToCallRepository
    private let toBuyRepository: ToBuyRepository
    private let toSellRepository: ToSellRepository
    private let syncRepository: SyncRepository
    private var cancellables = Set<AnyCancellable>()

    init() {
        let counterRepository = InMemoryHomeCounterRepository()
        self.counterRepository = counterRepository
        self.observeCountersUseCase = DefaultObserveHomeCountersUseCase(repository: counterRepository)

        let toCallApiClient = ToCallAPIClient()
        let toCallStore = SQLiteToCallStore()
        self.toCallRepository = RemoteToCallRepository(apiClient: toCallApiClient, store: toCallStore)
        observeToCallCount()

        let toBuyApiClient = ToBuyAPIClient()
        let wishlistStore = WishlistStore()
        let toBuyStore = InMemoryToBuyStore()
        self.toBuyRepository = RemoteToBuyRepository(
            apiClient: toBuyApiClient,
            wishlistStore: wishlistStore,
            store: toBuyStore
        )
        let observeToBuyItemsUseCase = DefaultObserveToBuyItemsUseCase(repository: toBuyRepository)
        let fetchToBuyItemsUseCase = DefaultFetchToBuyItemsUseCase(repository: toBuyRepository)
        self.startUpdatesUseCase = DefaultStartHomeCountersUpdatesUseCase(
            counterRepository: counterRepository,
            observeItemsUseCase: observeToBuyItemsUseCase,
            fetchItemsUseCase: fetchToBuyItemsUseCase
        )

        self.toSellRepository = LocalToSellRepository()
        self.syncRepository = HybridSyncRepository()
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            observeCountersUseCase: observeCountersUseCase,
            startUpdatesUseCase: startUpdatesUseCase
        )
    }

    func makeToCallViewModel() -> ToCallViewModel {
        let fetchPageUseCase = DefaultFetchToCallPageUseCase(repository: toCallRepository)
        let retryUseCase = DefaultRetryToCallUseCase(repository: toCallRepository)
        let observeUpdatesUseCase = DefaultObserveToCallUpdatesUseCase(repository: toCallRepository)
        return ToCallViewModel(
            fetchPageUseCase: fetchPageUseCase,
            retryUseCase: retryUseCase,
            observeUpdatesUseCase: observeUpdatesUseCase
        )
    }

    private func observeToCallCount() {
        let observeCountUseCase = DefaultObserveToCallCountUseCase(repository: toCallRepository)
        observeCountUseCase.execute()
            .sink { [weak self] count in
                self?.counterRepository.updateToCallCount(count)
            }
            .store(in: &cancellables)
    }

    func makeToBuyViewModel() -> ToBuyViewModel {
        let fetchItemsUseCase = DefaultFetchToBuyItemsUseCase(repository: toBuyRepository)
        let setWishlistUseCase = DefaultSetWishlistUseCase(repository: toBuyRepository)
        let observeItemsUseCase = DefaultObserveToBuyItemsUseCase(repository: toBuyRepository)
        return ToBuyViewModel(
            fetchItemsUseCase: fetchItemsUseCase,
            setWishlistUseCase: setWishlistUseCase,
            observeItemsUseCase: observeItemsUseCase
        )
    }

    func makeToBuyDetailViewModel(id: UUID) -> ToBuyDetailViewModel {
        let fetchDetailUseCase = DefaultFetchToBuyDetailUseCase(repository: toBuyRepository)
        let setWishlistUseCase = DefaultSetWishlistUseCase(repository: toBuyRepository)
        return ToBuyDetailViewModel(
            id: id,
            fetchDetailUseCase: fetchDetailUseCase,
            setWishlistUseCase: setWishlistUseCase
        )
    }

    func makeToSellViewModel() -> ToSellViewModel {
        let observeItemsUseCase = DefaultObserveToSellItemsUseCase(repository: toSellRepository)
        let mutateUseCase = DefaultMutateToSellItemUseCase(repository: toSellRepository)
        let updateToSellCountUseCase = DefaultUpdateToSellCountUseCase(repository: counterRepository)
        return ToSellViewModel(
            observeItemsUseCase: observeItemsUseCase,
            mutateUseCase: mutateUseCase,
            updateToSellCountUseCase: updateToSellCountUseCase
        )
    }

    func makeSyncViewModel() -> SyncViewModel {
        let observePending = DefaultObservePendingSyncUseCase(repository: syncRepository)
        let manualSync = DefaultPerformManualSyncUseCase(repository: syncRepository)
        return SyncViewModel(observePendingUseCase: observePending, manualSyncUseCase: manualSync)
    }
}
