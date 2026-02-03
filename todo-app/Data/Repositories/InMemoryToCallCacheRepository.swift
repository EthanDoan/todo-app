import Combine
import Foundation

final class InMemoryToCallCacheRepository: ToCallCacheRepository {
    private let subject = CurrentValueSubject<[ToCallPerson], Never>([])
    private(set) var lastSyncedAt: Date?
    private let pageSize = 10

    func observePeople() -> AnyPublisher<[ToCallPerson], Never> {
        subject.eraseToAnyPublisher()
    }

    func merge(people: [ToCallPerson], syncedAt: Date?) {
        var cachedPeople = subject.value
        var indexById: [UUID: Int] = [:]
        var newPeople: [ToCallPerson] = []

        for (index, person) in cachedPeople.enumerated() {
            indexById[person.id] = index
        }

        for person in people {
            let updatedPerson = ToCallPerson(
                id: person.id,
                name: person.name,
                phoneNumber: person.phoneNumber,
                lastSyncedAt: syncedAt
            )
            if let index = indexById[person.id] {
                cachedPeople[index] = updatedPerson
            } else {
                newPeople.append(updatedPerson)
            }
        }

        if !newPeople.isEmpty {
            cachedPeople.insert(contentsOf: newPeople, at: 0)
        }

        if let syncedAt {
            lastSyncedAt = syncedAt
        }

        subject.send(cachedPeople)
    }

    func page(page: Int, filter: ToCallFilter) -> ToCallPage {
        let searchText = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = subject.value.filter { person in
            guard let searchText, !searchText.isEmpty else { return true }
            return person.name.lowercased().contains(searchText)
                || person.phoneNumber.lowercased().contains(searchText)
        }

        let startIndex = max(0, (page - 1) * pageSize)
        let endIndex = min(startIndex + pageSize, filtered.count)
        let pageItems = startIndex < endIndex ? Array(filtered[startIndex..<endIndex]) : []
        let nextPage = endIndex < filtered.count ? page + 1 : nil

        return ToCallPage(items: pageItems, nextPage: nextPage, lastSyncedAt: lastSyncedAt)
    }
}
