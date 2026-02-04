import Foundation
import SQLite

final class SQLiteSellSyncStore {
    static let tableName = "SellSync"

    private let db: Connection
    private let table = Table(SQLiteSellSyncStore.tableName)
    private let id = Expression<String>("id")
    private let itemId = Expression<String>("item_id")
    private let soldAt = Expression<Double>("sold_at")
    private let syncedAt = Expression<Double?>("synced_at")

    init() {
        do {
            let dbURL = try Self.databaseURL()
            db = try Connection(dbURL.path)
            try configure()
        } catch {
            fatalError("Failed to initialize SQLite: \(error)")
        }
    }

    func fetchPending() throws -> [SellSyncItem] {
        var results: [SellSyncItem] = []
        let query = table.filter(syncedAt == nil).order(soldAt.asc)
        for row in try db.prepare(query) {
            results.append(mapRow(row))
        }
        return results
    }

    func insertPending(itemId: UUID, soldAt soldDate: Date) throws -> SellSyncItem {
        if let existing = try fetchPendingItem(for: itemId) {
            return existing
        }
        let syncId = UUID()
        let insert = table.insert(
            id <- syncId.uuidString,
            self.itemId <- itemId.uuidString,
            soldAt <- soldDate.timeIntervalSince1970,
            syncedAt <- nil
        )
        try db.run(insert)
        return SellSyncItem(id: syncId, itemId: itemId, soldAt: soldDate, syncedAt: nil)
    }

    func markSynced(ids: [UUID], syncedDate: Date) throws {
        guard !ids.isEmpty else { return }
        let idStrings = ids.map { $0.uuidString }
        let rows = table.filter(idStrings.contains(id))
        try db.run(rows.update(syncedAt <- syncedDate.timeIntervalSince1970))
    }

    private func fetchPendingItem(for itemId: UUID) throws -> SellSyncItem? {
        let query = table.filter(self.itemId == itemId.uuidString && syncedAt == nil).limit(1)
        guard let row = try db.pluck(query) else { return nil }
        return mapRow(row)
    }

    private func configure() throws {
        try db.run(table.create(ifNotExists: true) { builder in
            builder.column(id, primaryKey: true)
            builder.column(itemId)
            builder.column(soldAt)
            builder.column(syncedAt)
        })
    }

    private func mapRow(_ row: Row) -> SellSyncItem {
        let syncedDate = row[syncedAt].map { Date(timeIntervalSince1970: $0) }
        return SellSyncItem(
            id: UUID(uuidString: row[id]) ?? UUID(),
            itemId: UUID(uuidString: row[itemId]) ?? UUID(),
            soldAt: Date(timeIntervalSince1970: row[soldAt]),
            syncedAt: syncedDate
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
