import Combine
import Foundation

final class RemoteToCallRepository: ToCallRepository {
    private let apiClient: ToCallAPIClient
    private var lastRequest: (page: Int, filter: ToCallFilter)?

    init(apiClient: ToCallAPIClient) {
        self.apiClient = apiClient
    }

    func fetchPeople(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error> {
        lastRequest = (page, filter)
        return apiClient.fetchPeople(page: page, filter: filter)
    }

    func retryLastRequest() -> AnyPublisher<ToCallPage, Error> {
        guard let request = lastRequest else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        return apiClient.fetchPeople(page: request.page, filter: request.filter)
    }
}
