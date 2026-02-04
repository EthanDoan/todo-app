import Combine
import Foundation

final class RemoteToCallRepository: ToCallRepository {
    private let apiClient: ToCallAPIClient
    private let store: SQLiteToCallStore
    private let pageSize = 10
    private var lastRequest: (page: Int, filter: ToCallFilter)?
    private let updatesSubject = PassthroughSubject<[ToCallPerson], Never>()
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: ToCallAPIClient, store: SQLiteToCallStore) {
        self.apiClient = apiClient
        self.store = store
        observeServerUpdates()
    }

    func fetchPeople(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error> {
        lastRequest = (page, filter)
        return syncAndLoad(page: page, filter: filter)
    }

    func retryLastRequest() -> AnyPublisher<ToCallPage, Error> {
        guard let request = lastRequest else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        return syncAndLoad(page: request.page, filter: request.filter)
    }

    func observeUpdates() -> AnyPublisher<[ToCallPerson], Never> {
        updatesSubject.eraseToAnyPublisher()
    }

    private func syncAndLoad(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error> {
        let lastSyncedAt = (try? store.latestSyncedAt()) ?? nil
        return apiClient.fetchPeople(page: page, filter: filter, lastSyncedAt: lastSyncedAt)
            .tryMap { [weak self] response in
                guard let self else { return response }
                try self.store.upsert(people: response.items)
                let cachedPage = try self.store.fetchPage(page: page, pageSize: self.pageSize, filter: filter)
                return ToCallPage(
                    items: cachedPage.items,
                    nextPage: cachedPage.nextPage,
                    lastSyncedAt: response.lastSyncedAt
                )
            }
            .eraseToAnyPublisher()
    }

    private func observeServerUpdates() {
        apiClient.streamPeopleUpdates()
            .sink { [weak self] person in
                guard let self else { return }
                do {
                    try self.store.upsert(people: [person])
                    self.updatesSubject.send([person])
                } catch {
                    assertionFailure("Failed to persist streamed To-Call person: \(error)")
                }
            }
            .store(in: &cancellables)
    }
}
