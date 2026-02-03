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
    private let updateToCallCountUseCase: UpdateToCallCountUseCase
    private var cancellables = Set<AnyCancellable>()
    private var pageLoadCancellable: AnyCancellable?
    private var nextPageCancellable: AnyCancellable?
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

        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.applyFilter(text)
            }
            .store(in: &cancellables)
    }

    func loadFirstPage() {
        pageLoadCancellable?.cancel()
        nextPageCancellable?.cancel()
        isLoadingNextPage = false
        nextPage = nil
        hasNextPage = false
        pageLoadCancellable = fetchPageUseCase.execute(page: 1, filter: currentFilter)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] page in
                self?.people = page.items
                self?.lastSyncedAt = page.lastSyncedAt
                self?.nextPage = page.nextPage
                self?.hasNextPage = page.nextPage != nil
                self?.updateToCallCountUseCase.execute(count: page.items.count)
            })
    }

    func retryLastRequest() {
        pageLoadCancellable?.cancel()
        pageLoadCancellable = retryUseCase.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] page in
                self?.people = page.items
                self?.lastSyncedAt = page.lastSyncedAt
                self?.nextPage = page.nextPage
                self?.hasNextPage = page.nextPage != nil
                self?.updateToCallCountUseCase.execute(count: page.items.count)
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
                    self.nextPage = page.nextPage
                    self.hasNextPage = page.nextPage != nil
                    self.updateToCallCountUseCase.execute(count: self.people.count)
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
}
