import Combine

protocol StartHomeCountersUpdatesUseCase {
    func execute()
}

final class DefaultStartHomeCountersUpdatesUseCase: StartHomeCountersUpdatesUseCase {
    private let counterRepository: HomeCounterRepository
    private let observeItemsUseCase: ObserveToBuyItemsUseCase
    private let fetchItemsUseCase: FetchToBuyItemsUseCase
    private let observeToCallUseCase: ObserveToCallPeopleUseCase
    private var cancellables = Set<AnyCancellable>()
    private var hasStarted = false

    init(
        counterRepository: HomeCounterRepository,
        observeItemsUseCase: ObserveToBuyItemsUseCase,
        fetchItemsUseCase: FetchToBuyItemsUseCase,
        observeToCallUseCase: ObserveToCallPeopleUseCase
    ) {
        self.counterRepository = counterRepository
        self.observeItemsUseCase = observeItemsUseCase
        self.fetchItemsUseCase = fetchItemsUseCase
        self.observeToCallUseCase = observeToCallUseCase
    }

    func execute() {
        guard !hasStarted else { return }
        hasStarted = true

        fetchItemsUseCase.execute(sort: .titleAscending, filter: ToBuyFilter(searchText: nil, maxPrice: nil))
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        observeItemsUseCase.execute()
            .map(\.count)
            .sink { [weak self] count in
                self?.counterRepository.updateToBuyCount(count)
            }
            .store(in: &cancellables)

        observeToCallUseCase.execute()
            .map(\.count)
            .sink { [weak self] count in
                self?.counterRepository.updateToCallCount(count)
            }
            .store(in: &cancellables)
    }
}
