import Combine
import Foundation

final class ToCallAPIClient {
    struct ServerUpdate {
        let people: [ToCallPerson]
        let syncedAt: Date
    }

    private struct SeedPerson {
        let id: UUID
        let name: String
        let phoneNumber: String
    }

    private struct ServerPerson {
        let id: UUID
        var name: String
        var phoneNumber: String
        var lastUpdatedAt: Date
    }

    private let pageSize = 10
    private let seeds: [SeedPerson] = [
        SeedPerson(id: UUID(), name: "Alicia Green", phoneNumber: "(415) 555-0182"),
        SeedPerson(id: UUID(), name: "Ben Turner", phoneNumber: "(415) 555-0191"),
        SeedPerson(id: UUID(), name: "Carla Santos", phoneNumber: "(415) 555-0114"),
        SeedPerson(id: UUID(), name: "Derek Hughes", phoneNumber: "(415) 555-0177"),
        SeedPerson(id: UUID(), name: "Evelyn Chen", phoneNumber: "(415) 555-0139"),
        SeedPerson(id: UUID(), name: "Fatima Noor", phoneNumber: "(415) 555-0120"),
        SeedPerson(id: UUID(), name: "George Patel", phoneNumber: "(415) 555-0145"),
        SeedPerson(id: UUID(), name: "Hana Ishikawa", phoneNumber: "(415) 555-0166"),
        SeedPerson(id: UUID(), name: "Ivan Petrov", phoneNumber: "(415) 555-0152"),
        SeedPerson(id: UUID(), name: "Jordan Blake", phoneNumber: "(415) 555-0108"),
        SeedPerson(id: UUID(), name: "Kira Lopez", phoneNumber: "(415) 555-0189"),
        SeedPerson(id: UUID(), name: "Liam O'Connor", phoneNumber: "(415) 555-0172"),
        SeedPerson(id: UUID(), name: "Maya Singh", phoneNumber: "(415) 555-0198"),
        SeedPerson(id: UUID(), name: "Noah Rivera", phoneNumber: "(415) 555-0129"),
        SeedPerson(id: UUID(), name: "Priya Sharma", phoneNumber: "(415) 555-0117"),
        SeedPerson(id: UUID(), name: "Quinn Harper", phoneNumber: "(415) 555-0103"),
        SeedPerson(id: UUID(), name: "Rosa Martinez", phoneNumber: "(415) 555-0193"),
        SeedPerson(id: UUID(), name: "Samir Khan", phoneNumber: "(415) 555-0162"),
        SeedPerson(id: UUID(), name: "Tessa Miller", phoneNumber: "(415) 555-0131"),
        SeedPerson(id: UUID(), name: "Uma Patel", phoneNumber: "(415) 555-0149"),
        SeedPerson(id: UUID(), name: "Victor Alvarez", phoneNumber: "(415) 555-0187"),
        SeedPerson(id: UUID(), name: "Wendy Brooks", phoneNumber: "(415) 555-0110"),
        SeedPerson(id: UUID(), name: "Xavier Ortiz", phoneNumber: "(415) 555-0175"),
        SeedPerson(id: UUID(), name: "Yara Haddad", phoneNumber: "(415) 555-0126"),
        SeedPerson(id: UUID(), name: "Zane Cooper", phoneNumber: "(415) 555-0168"),
        SeedPerson(id: UUID(), name: "Amelia Rossi", phoneNumber: "(415) 555-0196"),
        SeedPerson(id: UUID(), name: "Bruno Silva", phoneNumber: "(415) 555-0105"),
        SeedPerson(id: UUID(), name: "Chloe Nguyen", phoneNumber: "(415) 555-0134"),
        SeedPerson(id: UUID(), name: "Diego Morales", phoneNumber: "(415) 555-0158"),
        SeedPerson(id: UUID(), name: "Elena Fischer", phoneNumber: "(415) 555-0141")
    ]
    private var people: [ServerPerson] = []
    private var fetchCount = 0
    private var newPersonCount = 0
    private let serverUpdatesSubject = PassthroughSubject<ServerUpdate, Never>()
    private var updateTimerCancellable: AnyCancellable?

    init() {
        let now = Date()
        self.people = seeds.map { seed in
            ServerPerson(id: seed.id, name: seed.name, phoneNumber: seed.phoneNumber, lastUpdatedAt: now)
        }
        startServerUpdates()
    }

    var serverUpdatesPublisher: AnyPublisher<ServerUpdate, Never> {
        serverUpdatesSubject.eraseToAnyPublisher()
    }

    func fetchPeople(page: Int, filter: ToCallFilter, since: Date?) -> AnyPublisher<ToCallPage, Error> {
        guard page > 0 else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        applyServerChanges()

        let searchText = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredPeople = people.filter { person in
            if let since, person.lastUpdatedAt <= since {
                return false
            }
            guard let searchText, !searchText.isEmpty else { return true }
            return person.name.lowercased().contains(searchText)
                || person.phoneNumber.lowercased().contains(searchText)
        }

        let items: [ServerPerson]
        let shouldReturnAll = since == nil && (searchText ?? "").isEmpty
        if shouldReturnAll {
            items = filteredPeople
        } else if since == nil {
            let startIndex = (page - 1) * pageSize
            let endIndex = min(startIndex + pageSize, filteredPeople.count)
            items = startIndex < endIndex ? Array(filteredPeople[startIndex..<endIndex]) : []
        } else {
            items = filteredPeople
        }

        let lastSyncedAt = Date()
        let resultPeople = items.map {
            ToCallPerson(id: $0.id, name: $0.name, phoneNumber: $0.phoneNumber, lastSyncedAt: lastSyncedAt)
        }

        let nextPage: Int?
        if shouldReturnAll {
            nextPage = nil
        } else if since == nil {
            let startIndex = (page - 1) * pageSize
            let endIndex = min(startIndex + pageSize, filteredPeople.count)
            nextPage = endIndex < filteredPeople.count ? page + 1 : nil
        } else {
            nextPage = nil
        }
        let response = ToCallPage(items: resultPeople, nextPage: nextPage, lastSyncedAt: lastSyncedAt)

        return Just(response)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private func applyServerChanges() {
        fetchCount += 1
        guard !people.isEmpty else { return }

        let changeIndex = fetchCount % people.count
        let now = Date()
        people[changeIndex].lastUpdatedAt = now
    }

    private func startServerUpdates() {
        updateTimerCancellable = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.appendNewPerson()
            }
    }

    private func appendNewPerson() {
        newPersonCount += 1
        let now = Date()
        let newPerson = ServerPerson(
            id: UUID(),
            name: "New Contact \(newPersonCount)",
            phoneNumber: String(format: "(415) 555-%04d", 2000 + newPersonCount),
            lastUpdatedAt: now
        )
        people.append(newPerson)
        let toCallPerson = ToCallPerson(
            id: newPerson.id,
            name: newPerson.name,
            phoneNumber: newPerson.phoneNumber,
            lastSyncedAt: now
        )
        serverUpdatesSubject.send(ServerUpdate(people: [toCallPerson], syncedAt: now))
    }
}
