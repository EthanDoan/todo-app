import Foundation
import SQLite

final class SQLiteItemToSellStore {
    static let tableName = "ItemToSell"

    private let db: Connection
    private let table = Table(SQLiteItemToSellStore.tableName)
    private let id = Expression<String>("id")
    private let title = Expression<String>("title")
    private let price = Expression<String>("price")
    private let isSold = Expression<Bool>("is_sold")
    private let createdAt = Expression<Double>("created_at")

    init() {
        do {
            let dbURL = try Self.databaseURL()
            db = try Connection(dbURL.path)
            try configure()
        } catch {
            fatalError("Failed to initialize SQLite: \(error)")
        }
    }

    func fetchAll() throws -> [ToSellItem] {
        var results: [ToSellItem] = []
        for row in try db.prepare(table.order(createdAt.asc)) {
            results.append(mapRow(row))
        }
        return results
    }

    func insertItem(title: String, price: Decimal, isSold: Bool) throws -> ToSellItem {
        let itemId = UUID()
        let item = ToSellItem(id: itemId, title: title, price: price, isSold: isSold)
        let insert = table.insert(
            id <- itemId.uuidString,
            self.title <- title,
            self.price <- priceString(from: price),
            self.isSold <- isSold,
            createdAt <- Date().timeIntervalSince1970
        )
        try db.run(insert)
        return item
    }

    func updateItem(_ item: ToSellItem) throws {
        let row = table.filter(id == item.id.uuidString)
        try db.run(row.update(
            title <- item.title,
            price <- priceString(from: item.price),
            isSold <- item.isSold
        ))
    }

    func deleteItem(id itemId: UUID) throws {
        let row = table.filter(id == itemId.uuidString)
        try db.run(row.delete())
    }

    func deleteItems(ids: [UUID]) throws {
        let idStrings = ids.map { $0.uuidString }
        let row = table.filter(id.in(idStrings))
        try db.run(row.delete())
    }

    func replaceAll(with items: [ToSellItem]) throws {
        try db.transaction {
            try db.run(table.delete())
            for item in items {
                let insert = table.insert(
                    id <- item.id.uuidString,
                    title <- item.title,
                    price <- priceString(from: item.price),
                    isSold <- item.isSold,
                    createdAt <- Date().timeIntervalSince1970
                )
                try db.run(insert)
            }
        }
    }

    private func configure() throws {
        try db.run(table.create(ifNotExists: true) { builder in
            builder.column(id, primaryKey: true)
            builder.column(title)
            builder.column(price)
            builder.column(isSold)
            builder.column(createdAt)
        })
    }

    private func mapRow(_ row: Row) -> ToSellItem {
        let priceValue = Decimal(string: row[price]) ?? 0
        return ToSellItem(
            id: UUID(uuidString: row[id]) ?? UUID(),
            title: row[title],
            price: priceValue,
            isSold: row[isSold]
        )
    }

    private func priceString(from price: Decimal) -> String {
        NSDecimalNumber(decimal: price).stringValue
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
