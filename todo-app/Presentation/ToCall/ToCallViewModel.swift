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
    private let observeUpdatesUseCase: ObserveToCallUpdatesUseCase
    private var cancellables = Set<AnyCancellable>()
    private var pageLoadCancellable: AnyCancellable?
    private var nextPageCancellable: AnyCancellable?
    private var nextPage: Int?
    private var currentFilter = ToCallFilter(searchText: nil)

    init(
        fetchPageUseCase: FetchToCallPageUseCase,
        retryUseCase: RetryToCallUseCase,
        observeUpdatesUseCase: ObserveToCallUpdatesUseCase
    ) {
        self.fetchPageUseCase = fetchPageUseCase
        self.retryUseCase = retryUseCase
        self.observeUpdatesUseCase = observeUpdatesUseCase

        $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] text in
                self?.applyFilter(text)
            }
            .store(in: &cancellables)

        observeUpdatesUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updates in
                self?.handleIncomingUpdates(updates)
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

    private func handleIncomingUpdates(_ updates: [ToCallPerson]) {
        let filteredUpdates = updates.filter { matchesFilter($0, filter: currentFilter) }
        guard !filteredUpdates.isEmpty else { return }
        let existingIds = Set(people.map(\.id))
        let newPeople = filteredUpdates.filter { !existingIds.contains($0.id) }
        guard !newPeople.isEmpty else { return }
        people.insert(contentsOf: newPeople, at: 0)
        people.sort { ($0.lastSyncedAt ?? .distantPast) > ($1.lastSyncedAt ?? .distantPast) }
        lastSyncedAt = Date()
    }

    private func matchesFilter(_ person: ToCallPerson, filter: ToCallFilter) -> Bool {
        guard let searchText = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !searchText.isEmpty else {
            return true
        }
        let lowered = searchText.lowercased()
        return person.name.lowercased().contains(lowered)
            || person.phoneNumber.lowercased().contains(lowered)
    }
}
