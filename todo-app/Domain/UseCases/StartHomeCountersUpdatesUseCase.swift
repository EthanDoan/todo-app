import Combine

protocol StartHomeCountersUpdatesUseCase {
    func execute()
}

final class DefaultStartHomeCountersUpdatesUseCase: StartHomeCountersUpdatesUseCase {
    private let counterRepository: HomeCounterRepository
    private let toBuyRepository: ToBuyRepository
    private var cancellables = Set<AnyCancellable>()
    private var currentToBuyCount = 0
    private var hasStarted = false

    init(counterRepository: HomeCounterRepository, toBuyRepository: ToBuyRepository) {
        self.counterRepository = counterRepository
        self.toBuyRepository = toBuyRepository
    }

    func execute() {
        guard !hasStarted else { return }
        hasStarted = true

        toBuyRepository.fetchItems(sort: .titleAscending, filter: ToBuyFilter(searchText: nil, maxPrice: nil))
            .replaceError(with: [])
            .map(\.count)
            .sink { [weak self] count in
                guard let self else { return }
                currentToBuyCount = count
                counterRepository.updateToBuyCount(count)
            }
            .store(in: &cancellables)

        toBuyRepository.observeNewItems()
            .sink { [weak self] _ in
                guard let self else { return }
                currentToBuyCount += 1
                counterRepository.updateToBuyCount(currentToBuyCount)
            }
            .store(in: &cancellables)
    }
}
