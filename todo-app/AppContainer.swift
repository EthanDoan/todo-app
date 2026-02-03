import Foundation

final class AppContainer {
    private let counterRepository: HomeCounterRepository
    private let observeCountersUseCase: ObserveHomeCountersUseCase
    private let startUpdatesUseCase: StartHomeCountersUpdatesUseCase

    private let toCallRepository: ToCallRepository
    private let toBuyRepository: ToBuyRepository
    private let toSellRepository: ToSellRepository
    private let syncRepository: SyncRepository

    init() {
        let counterRepository = InMemoryHomeCounterRepository()
        self.counterRepository = counterRepository
        self.observeCountersUseCase = DefaultObserveHomeCountersUseCase(repository: counterRepository)

        let toCallApiClient = ToCallAPIClient()
        self.toCallRepository = RemoteToCallRepository(apiClient: toCallApiClient)

        let toBuyApiClient = ToBuyAPIClient()
        let wishlistStore = WishlistStore()
        self.toBuyRepository = RemoteToBuyRepository(apiClient: toBuyApiClient, wishlistStore: wishlistStore)
        self.startUpdatesUseCase = DefaultStartHomeCountersUpdatesUseCase(
            counterRepository: counterRepository,
            toBuyRepository: toBuyRepository
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
        let updateToCallCountUseCase = DefaultUpdateToCallCountUseCase(repository: counterRepository)
        return ToCallViewModel(
            fetchPageUseCase: fetchPageUseCase,
            retryUseCase: retryUseCase,
            updateToCallCountUseCase: updateToCallCountUseCase
        )
    }

    func makeToBuyViewModel() -> ToBuyViewModel {
        let fetchItemsUseCase = DefaultFetchToBuyItemsUseCase(repository: toBuyRepository)
        let setWishlistUseCase = DefaultSetWishlistUseCase(repository: toBuyRepository)
        let updateToBuyCountUseCase = DefaultUpdateToBuyCountUseCase(repository: counterRepository)
        return ToBuyViewModel(
            fetchItemsUseCase: fetchItemsUseCase,
            setWishlistUseCase: setWishlistUseCase,
            updateToBuyCountUseCase: updateToBuyCountUseCase
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
