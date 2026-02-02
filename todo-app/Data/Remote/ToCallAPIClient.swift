import Combine
import Foundation

final class ToCallAPIClient {
    func fetchPeople(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error> {
        Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
}
