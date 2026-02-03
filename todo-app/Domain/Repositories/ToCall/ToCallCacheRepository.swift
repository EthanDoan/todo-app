import Combine
import Foundation

protocol ToCallCacheRepository {
    func observePeople() -> AnyPublisher<[ToCallPerson], Never>
    func page(page: Int, filter: ToCallFilter) -> ToCallPage
    var lastSyncedAt: Date? { get }
}
