import Combine
import Foundation

final class ToCallViewModel: ObservableObject {
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var people: [ToCallPerson] = []

    private let fetchPageUseCase: FetchToCallPageUseCase
    private let retryUseCase: RetryToCallUseCase
    private let updateToCallCountUseCase: UpdateToCallCountUseCase
    private var cancellables = Set<AnyCancellable>()

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
        fetchPageUseCase.execute(page: 1, filter: ToCallFilter(searchText: nil))
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] page in
                self?.people = page.items
                self?.lastSyncedAt = page.lastSyncedAt
                self?.updateToCallCountUseCase.execute(count: page.items.count)
            })
            .store(in: &cancellables)
    }

    func retryLastRequest() {
        retryUseCase.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] page in
                self?.people = page.items
                self?.lastSyncedAt = page.lastSyncedAt
                self?.updateToCallCountUseCase.execute(count: page.items.count)
            })
            .store(in: &cancellables)
    }
}
