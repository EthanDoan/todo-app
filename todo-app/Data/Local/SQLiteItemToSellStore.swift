import Foundation
import SQLite

final class SQLiteItemToSellStore {
    static let tableName = "ItemToSell"

    private let db: Connection
    private let table = Table(SQLiteItemToSellStore.tableName)
    private let id = Expression<String>("id")
    private let title = Expression<String>("title")
    private let price = Expression<Double>("price")
    private let isSold = Expression<Bool>("isSold")

    init(databaseURL: URL = SQLiteItemToSellStore.defaultDatabaseURL()) throws {
        db = try Connection(databaseURL.path)
        try db.run(
            table.create(ifNotExists: true) { table in
                table.column(id, primaryKey: true)
                table.column(title)
                table.column(price)
                table.column(isSold)
            }
        )
    }

    func fetchAll() throws -> [ToSellItem] {
        let query = table.order(title.asc, id.asc)
        return try db.prepare(query).compactMap { row in
            guard let uuid = UUID(uuidString: row[id]) else {
                return nil
            }
            return ToSellItem(
                id: uuid,
                title: row[title],
                price: Decimal(row[price]),
                isSold: row[isSold]
            )
        }
    }

    func insert(item: ToSellItem) throws {
        try db.run(
            table.insert(
                id <- item.id.uuidString,
                title <- item.title,
                price <- NSDecimalNumber(decimal: item.price).doubleValue,
                isSold <- item.isSold
            )
        )
    }

    func update(item: ToSellItem) throws {
        let query = table.filter(id == item.id.uuidString)
        try db.run(
            query.update(
                title <- item.title,
                price <- NSDecimalNumber(decimal: item.price).doubleValue,
                isSold <- item.isSold
            )
        )
    }

    func delete(id: UUID) throws {
        let query = table.filter(self.id == id.uuidString)
        try db.run(query.delete())
    }

    func delete(ids: [UUID]) throws {
        try db.transaction {
            for id in ids {
                let query = table.filter(self.id == id.uuidString)
                try db.run(query.delete())
            }
        }
    }

    func replaceAll(items: [ToSellItem]) throws {
        try db.transaction {
            try db.run(table.delete())
            for item in items {
                try db.run(
                    table.insert(
                        id <- item.id.uuidString,
                        title <- item.title,
                        price <- NSDecimalNumber(decimal: item.price).doubleValue,
                        isSold <- item.isSold
                    )
                )
            }
        }
    }

    private static func defaultDatabaseURL() -> URL {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return (baseURL ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("todo-app.sqlite3")
    }
}
