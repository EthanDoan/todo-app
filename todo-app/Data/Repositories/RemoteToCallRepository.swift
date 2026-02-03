import Combine
import Foundation

final class RemoteToCallRepository: ToCallRepository {
    private let apiClient: ToCallAPIClient
    private let cache: InMemoryToCallCacheRepository
    private var lastRequest: (page: Int, filter: ToCallFilter)?
    private let pageSize = 10
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: ToCallAPIClient, cache: InMemoryToCallCacheRepository) {
        self.apiClient = apiClient
        self.cache = cache
        observeServerUpdates()
    }

    func fetchPeople(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error> {
        lastRequest = (page, filter)
        guard page > 0 else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        if page == 1 {
            return apiClient.fetchPeople(page: page, filter: ToCallFilter(searchText: nil), since: cache.lastSyncedAt)
                .map { [weak self] response in
                    guard let self else { return response }
                    self.cache.merge(people: response.items, syncedAt: response.lastSyncedAt)
                    return self.cache.page(page: page, pageSize: self.pageSize, filter: filter)
                }
                .eraseToAnyPublisher()
        }

        let pageResult = cache.page(page: page, pageSize: pageSize, filter: filter)
        return Just(pageResult)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func retryLastRequest() -> AnyPublisher<ToCallPage, Error> {
        guard let request = lastRequest else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        return fetchPeople(page: request.page, filter: request.filter)
    }

    private func observeServerUpdates() {
        apiClient.serverUpdatesPublisher
            .sink { [weak self] update in
                self?.cache.merge(people: update.people, syncedAt: update.syncedAt)
            }
            .store(in: &cancellables)
    }
}
