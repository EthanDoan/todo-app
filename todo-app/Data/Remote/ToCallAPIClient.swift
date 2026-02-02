import Combine
import Foundation

final class ToCallAPIClient {
    private struct SeedPerson {
        let name: String
        let phoneNumber: String
    }

    private let pageSize = 5
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
        SeedPerson(name: "Priya Sharma", phoneNumber: "(415) 555-0117")
    ]

    func fetchPeople(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error> {
        guard page > 0 else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        let searchText = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredSeeds = seeds.filter { seed in
            guard let searchText, !searchText.isEmpty else { return true }
            return seed.name.lowercased().contains(searchText)
                || seed.phoneNumber.lowercased().contains(searchText)
        }

        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, filteredSeeds.count)
        let pageSeeds = startIndex < endIndex ? Array(filteredSeeds[startIndex..<endIndex]) : []

        let lastSyncedAt = Date()
        let people = pageSeeds.map {
            ToCallPerson(id: UUID(), name: $0.name, phoneNumber: $0.phoneNumber, lastSyncedAt: lastSyncedAt)
        }

        let nextPage = endIndex < filteredSeeds.count ? page + 1 : nil
        let response = ToCallPage(items: people, nextPage: nextPage, lastSyncedAt: lastSyncedAt)

        return Just(response)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
