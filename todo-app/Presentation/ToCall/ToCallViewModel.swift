import Combine
import Foundation

final class ToCallViewModel: ObservableObject {
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var people: [ToCallPerson] = []
    @Published private(set) var hasNextPage = false
    @Published private(set) var isLoadingNextPage = false
    @Published var searchText = ""

    private let fetchPageUseCase: FetchToCallPageUseCase
    private let retryUseCase: RetryToCallUseCase
    private let observeToCallUseCase: ObserveToCallPeopleUseCase
    private let fetchCachedPageUseCase: FetchCachedToCallPageUseCase
    private var cancellables = Set<AnyCancellable>()
    private var pageLoadCancellable: AnyCancellable?
    private var nextPageCancellable: AnyCancellable?
    private var nextPage: Int?
    private var currentPage = 1
    private var currentFilter = ToCallFilter(searchText: nil)
    private var hasLoadedOnce = false

    init(
        fetchPageUseCase: FetchToCallPageUseCase,
        retryUseCase: RetryToCallUseCase,
        observeToCallUseCase: ObserveToCallPeopleUseCase,
        fetchCachedPageUseCase: FetchCachedToCallPageUseCase
    ) {
        self.fetchPageUseCase = fetchPageUseCase
        self.retryUseCase = retryUseCase
        self.observeToCallUseCase = observeToCallUseCase
        self.fetchCachedPageUseCase = fetchCachedPageUseCase

        $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] text in
                self?.applyFilter(text)
            }
            .store(in: &cancellables)

        observeToCallUseCase.execute()
            .sink { [weak self] _ in
                self?.refreshFromCache()
            }
            .store(in: &cancellables)
    }

    func loadFirstPage() {
        pageLoadCancellable?.cancel()
        nextPageCancellable?.cancel()
        isLoadingNextPage = false
        nextPage = nil
        hasNextPage = false
        currentPage = 1
        hasLoadedOnce = true
        pageLoadCancellable = fetchPageUseCase.execute(page: 1, filter: currentFilter)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] page in
                self?.people = page.items
                self?.lastSyncedAt = page.lastSyncedAt
                self?.nextPage = page.nextPage
                self?.hasNextPage = page.nextPage != nil
            })
    }

    func retryLastRequest() {
        pageLoadCancellable?.cancel()
        hasLoadedOnce = true
        pageLoadCancellable = retryUseCase.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] page in
                self?.people = page.items
                self?.lastSyncedAt = page.lastSyncedAt
                self?.nextPage = page.nextPage
                self?.hasNextPage = page.nextPage != nil
            })
    }

    func loadNextPage() {
        guard let nextPage, !isLoadingNextPage else { return }
        isLoadingNextPage = true
        nextPageCancellable?.cancel()
        nextPageCancellable = fetchPageUseCase.execute(page: nextPage, filter: currentFilter)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isLoadingNextPage = false
                },
                receiveValue: { [weak self] page in
                    guard let self else { return }
                    self.people.append(contentsOf: page.items)
                    self.lastSyncedAt = page.lastSyncedAt
                    self.currentPage = nextPage
                    self.nextPage = page.nextPage
                    self.hasNextPage = page.nextPage != nil
                }
            )
    }

    func loadNextPageIfNeeded(currentItem: ToCallPerson) {
        guard hasNextPage, currentItem.id == people.last?.id else { return }
        loadNextPage()
    }

    private func applyFilter(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        currentFilter = ToCallFilter(searchText: trimmed.isEmpty ? nil : trimmed)
        loadFirstPage()
    }

    private func refreshFromCache() {
        guard hasLoadedOnce else { return }
        var combinedItems: [ToCallPerson] = []
        var pageIndex = 1
        var latestPage: ToCallPage?

        while pageIndex <= currentPage {
            let cachedPage = fetchCachedPageUseCase.execute(page: pageIndex, filter: currentFilter)
            combinedItems.append(contentsOf: cachedPage.items)
            latestPage = cachedPage
            if cachedPage.nextPage == nil { break }
            pageIndex += 1
        }

        people = combinedItems
        lastSyncedAt = latestPage?.lastSyncedAt
        nextPage = latestPage?.nextPage
        hasNextPage = latestPage?.nextPage != nil
    }
}
