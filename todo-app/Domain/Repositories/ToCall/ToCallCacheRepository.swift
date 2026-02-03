import Combine
import Foundation

protocol ToCallCacheRepository {
    func observePeople() -> AnyPublisher<[ToCallPerson], Never>
    var lastSyncedAt: Date? { get }
}
