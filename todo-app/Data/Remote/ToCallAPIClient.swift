import Combine
import Foundation

final class ToCallAPIClient {
    private struct SeedPerson {
        let name: String
        let phoneNumber: String
    }

    private struct ServerPerson {
        let id: UUID
        let name: String
        let phoneNumber: String
        let createdAt: Date
    }

    private let pageSize = 10
    private let streamInterval: TimeInterval = 15
    private let serverQueue = DispatchQueue(label: "tocall.server.queue")
    private let streamSubject = PassthroughSubject<ToCallPerson, Never>()
    private var streamCancellable: AnyCancellable?
    private var seedCursor = 0
    private var serverPeople: [ServerPerson] = []
    private let seeds: [SeedPerson] = [
        SeedPerson(name: "Alicia Green", phoneNumber: "(415) 555-0182"),
        SeedPerson(name: "Ben Turner", phoneNumber: "(415) 555-0191"),
        SeedPerson(name: "Carla Santos", phoneNumber: "(415) 555-0114"),
        SeedPerson(name: "Derek Hughes", phoneNumber: "(415) 555-0177"),
        SeedPerson(name: "Evelyn Chen", phoneNumber: "(415) 555-0139"),
        SeedPerson(name: "Fatima Noor", phoneNumber: "(415) 555-0120"),
        SeedPerson(name: "George Patel", phoneNumber: "(415) 555-0145"),
        SeedPerson(name: "Hana Ishikawa", phoneNumber: "(415) 555-0166"),
        SeedPerson(name: "Ivan Petrov", phoneNumber: "(415) 555-0152"),
        SeedPerson(name: "Jordan Blake", phoneNumber: "(415) 555-0108"),
        SeedPerson(name: "Kira Lopez", phoneNumber: "(415) 555-0189"),
        SeedPerson(name: "Liam O'Connor", phoneNumber: "(415) 555-0172"),
        SeedPerson(name: "Maya Singh", phoneNumber: "(415) 555-0198"),
        SeedPerson(name: "Noah Rivera", phoneNumber: "(415) 555-0129"),
        SeedPerson(name: "Priya Sharma", phoneNumber: "(415) 555-0117"),
        SeedPerson(name: "Quinn Harper", phoneNumber: "(415) 555-0103"),
        SeedPerson(name: "Rosa Martinez", phoneNumber: "(415) 555-0193"),
        SeedPerson(name: "Samir Khan", phoneNumber: "(415) 555-0162"),
        SeedPerson(name: "Tessa Miller", phoneNumber: "(415) 555-0131"),
        SeedPerson(name: "Uma Patel", phoneNumber: "(415) 555-0149"),
        SeedPerson(name: "Victor Alvarez", phoneNumber: "(415) 555-0187"),
        SeedPerson(name: "Wendy Brooks", phoneNumber: "(415) 555-0110"),
        SeedPerson(name: "Xavier Ortiz", phoneNumber: "(415) 555-0175"),
        SeedPerson(name: "Yara Haddad", phoneNumber: "(415) 555-0126"),
        SeedPerson(name: "Zane Cooper", phoneNumber: "(415) 555-0168"),
        SeedPerson(name: "Amelia Rossi", phoneNumber: "(415) 555-0196"),
        SeedPerson(name: "Bruno Silva", phoneNumber: "(415) 555-0105"),
        SeedPerson(name: "Chloe Nguyen", phoneNumber: "(415) 555-0134"),
        SeedPerson(name: "Diego Morales", phoneNumber: "(415) 555-0158"),
        SeedPerson(name: "Elena Fischer", phoneNumber: "(415) 555-0141")
    ]

    init() {
        seedInitialData()
        startStreaming()
    }

    func streamPeopleUpdates() -> AnyPublisher<ToCallPerson, Never> {
        streamSubject.eraseToAnyPublisher()
    }

    func fetchPeople(page: Int, filter: ToCallFilter, lastSyncedAt: Date?) -> AnyPublisher<ToCallPage, Error> {
        guard page > 0 else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        let syncTime = Date()
        let trimmedSearch = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return Deferred {
            Future { [weak self] promise in
                self?.serverQueue.async {
                    guard let self else { return }
                    let lowerBound = lastSyncedAt ?? .distantPast
                    let filteredPeople = self.serverPeople.filter { person in
                        person.createdAt > lowerBound && person.createdAt <= syncTime
                    }
                    let searchedPeople = filteredPeople.filter { person in
                        guard let trimmedSearch, !trimmedSearch.isEmpty else { return true }
                        return person.name.lowercased().contains(trimmedSearch)
                            || person.phoneNumber.lowercased().contains(trimmedSearch)
                    }

                    let startIndex = (page - 1) * self.pageSize
                    let endIndex = min(startIndex + self.pageSize, searchedPeople.count)
                    let pagePeople = startIndex < endIndex ? Array(searchedPeople[startIndex..<endIndex]) : []

                    let mapped = pagePeople.map { person in
                        ToCallPerson(
                            id: person.id,
                            name: person.name,
                            phoneNumber: person.phoneNumber,
                            lastSyncedAt: person.createdAt
                        )
                    }
                    let nextPage = endIndex < searchedPeople.count ? page + 1 : nil
                    let response = ToCallPage(items: mapped, nextPage: nextPage, lastSyncedAt: syncTime)
                    promise(.success(response))
                }
            }
        }
        .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func seedInitialData() {
        let now = Date()
        let seeded = seeds.enumerated().map { index, seed in
            let createdAt = now.addingTimeInterval(TimeInterval(-120 * (seeds.count - index)))
            return ServerPerson(id: UUID(), name: seed.name, phoneNumber: seed.phoneNumber, createdAt: createdAt)
        }
        serverPeople = seeded
    }

    private func startStreaming() {
        streamCancellable = Timer.publish(every: streamInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.generateNextPerson()
            }
    }

    private func generateNextPerson() {
        serverQueue.async { [weak self] in
            guard let self else { return }
            let seed = self.seeds[self.seedCursor % self.seeds.count]
            self.seedCursor += 1
            let suffix = self.seedCursor / self.seeds.count
            let name = suffix > 0 ? "\(seed.name) \(suffix + 1)" : seed.name
            let person = ServerPerson(id: UUID(), name: name, phoneNumber: seed.phoneNumber, createdAt: Date())
            self.serverPeople.append(person)
            let mapped = ToCallPerson(
                id: person.id,
                name: person.name,
                phoneNumber: person.phoneNumber,
                lastSyncedAt: person.createdAt
            )
            self.streamSubject.send(mapped)
        }
    }
}
