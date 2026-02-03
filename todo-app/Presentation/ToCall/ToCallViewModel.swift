import Combine
import Foundation

final class ToCallViewModel: ObservableObject {
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var people: [ToCallPerson] = []
    @Published private(set) var hasNextPage = false
    @Published private(set) var isLoadingNextPage = false

    private let fetchPageUseCase: FetchToCallPageUseCase
    private let retryUseCase: RetryToCallUseCase
    private let updateToCallCountUseCase: UpdateToCallCountUseCase
    private var cancellables = Set<AnyCancellable>()
    private var nextPage: Int?
    private var currentFilter = ToCallFilter(searchText: nil)

    init(
        fetchPageUseCase: FetchToCallPageUseCase,
        retryUseCase: RetryToCallUseCase,
        updateToCallCountUseCase: UpdateToCallCountUseCase
    ) {
        self.fetchPageUseCase = fetchPageUseCase
        self.retryUseCase = retryUseCase
        self.updateToCallCountUseCase = updateToCallCountUseCase
    }

    func loadFirstPage() {
        currentFilter = ToCallFilter(searchText: nil)
        isLoadingNextPage = false
        nextPage = nil
        hasNextPage = false
        fetchPageUseCase.execute(page: 1, filter: currentFilter)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] page in
                self?.people = page.items
                self?.lastSyncedAt = page.lastSyncedAt
                self?.nextPage = page.nextPage
                self?.hasNextPage = page.nextPage != nil
                self?.updateToCallCountUseCase.execute(count: page.items.count)
            })
            .store(in: &cancellables)
    }

    func retryLastRequest() {
        retryUseCase.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] page in
                self?.people = page.items
                self?.lastSyncedAt = page.lastSyncedAt
                self?.nextPage = page.nextPage
                self?.hasNextPage = page.nextPage != nil
                self?.updateToCallCountUseCase.execute(count: page.items.count)
            })
            .store(in: &cancellables)
    }

    func loadNextPage() {
        guard let nextPage, !isLoadingNextPage else { return }
        isLoadingNextPage = true
        fetchPageUseCase.execute(page: nextPage, filter: currentFilter)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isLoadingNextPage = false
                },
                receiveValue: { [weak self] page in
                    guard let self else { return }
                    self.people.append(contentsOf: page.items)
                    self.lastSyncedAt = page.lastSyncedAt
                    self.nextPage = page.nextPage
                    self.hasNextPage = page.nextPage != nil
                    self.updateToCallCountUseCase.execute(count: self.people.count)
                }
            )
            .store(in: &cancellables)
    }

    func loadNextPageIfNeeded(currentItem: ToCallPerson) {
        guard hasNextPage, currentItem.id == people.last?.id else { return }
        loadNextPage()
    }
}
