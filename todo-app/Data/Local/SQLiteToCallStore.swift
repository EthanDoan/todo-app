import Foundation
import SQLite

final class SQLiteToCallStore {
    static let tableName = "ToCallPerson"

    private let db: Connection
    private let table = Table(SQLiteToCallStore.tableName)
    private let id = Expression<String>("id")
    private let name = Expression<String>("name")
    private let phoneNumber = Expression<String>("phone_number")
    private let lastSyncedAt = Expression<Double>("last_synced_at")

    init() {
        do {
            let dbURL = try Self.databaseURL()
            db = try Connection(dbURL.path)
            try configure()
        } catch {
            fatalError("Failed to initialize SQLite: \(error)")
        }
    }

    func fetchPage(page: Int, pageSize: Int, filter: ToCallFilter) throws -> ToCallPage {
        guard page > 0 else {
            throw URLError(.badURL)
        }

        var baseQuery = table
        if let searchText = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !searchText.isEmpty {
            let pattern = "%\(searchText)%"
            baseQuery = baseQuery.filter(name.like(pattern) || phoneNumber.like(pattern))
        }

        let totalCount = try db.scalar(baseQuery.count)
        let offset = (page - 1) * pageSize
        let rows = try db.prepare(
            baseQuery
                .order(lastSyncedAt.desc)
                .limit(pageSize, offset: offset)
        )

        let items = rows.map(mapRow)
        let nextPage = offset + pageSize < totalCount ? page + 1 : nil
        return ToCallPage(items: items, nextPage: nextPage, lastSyncedAt: nil)
    }

    func upsert(people: [ToCallPerson]) throws {
        guard !people.isEmpty else { return }
        try db.transaction {
            for person in people {
                let timestamp = person.lastSyncedAt?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
                let insert = table.insert(
                    or: .replace,
                    id <- person.id.uuidString,
                    name <- person.name,
                    phoneNumber <- person.phoneNumber,
                    lastSyncedAt <- timestamp
                )
                try db.run(insert)
            }
        }
    }

    func latestSyncedAt() throws -> Date? {
        guard let row = try db.pluck(table.order(lastSyncedAt.desc).limit(1)) else {
            return nil
        }
        return Date(timeIntervalSince1970: row[lastSyncedAt])
    }

    private func configure() throws {
        try db.run(table.create(ifNotExists: true) { builder in
            builder.column(id, primaryKey: true)
            builder.column(name)
            builder.column(phoneNumber)
            builder.column(lastSyncedAt)
        })
    }

    private func mapRow(_ row: Row) -> ToCallPerson {
        ToCallPerson(
            id: UUID(uuidString: row[id]) ?? UUID(),
            name: row[name],
            phoneNumber: row[phoneNumber],
            lastSyncedAt: Date(timeIntervalSince1970: row[lastSyncedAt])
        )
    }

    private static func databaseURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return directory.appendingPathComponent("todo-app.sqlite3")
    }
}
