import Combine
import Foundation

final class LocalToSellRepository: ToSellRepository {
    private let store = SQLiteItemToSellStore()
    private let subject = CurrentValueSubject<[ToSellItem], Never>([])
    private var deletedStack: [[ToSellItem]] = []

    init() {
        refreshItems()
    }

    var itemsPublisher: AnyPublisher<[ToSellItem], Never> {
        subject.eraseToAnyPublisher()
    }

    func addItem(title: String, price: Decimal) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ToSellValidationError(message: "Title is required.")
        }
        guard price > 0 else {
            throw ToSellValidationError(message: "Price must be greater than zero.")
        }
        _ = try store.insertItem(title: trimmedTitle, price: price, isSold: false)
        refreshItems()
    }

    func updateItem(_ item: ToSellItem) throws {
        let trimmedTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ToSellValidationError(message: "Title is required.")
        }
        guard item.price > 0 else {
            throw ToSellValidationError(message: "Price must be greater than zero.")
        }
        let updated = ToSellItem(id: item.id, title: trimmedTitle, price: item.price, isSold: item.isSold)
        try store.updateItem(updated)
        refreshItems()
    }

    func deleteItem(id: UUID) {
        let items = subject.value
        deletedStack.append(items)
        do {
            try store.deleteItem(id: id)
            refreshItems()
        } catch {
            restoreFromSnapshot(items)
        }
    }

    func bulkDelete(ids: [UUID]) {
        let items = subject.value
        deletedStack.append(items)
        do {
            try store.deleteItems(ids: ids)
            refreshItems()
        } catch {
            restoreFromSnapshot(items)
        }
    }

    func undoDelete() -> Bool {
        guard let previous = deletedStack.popLast() else {
            return false
        }
        do {
            try store.replaceAll(with: previous)
            refreshItems()
        } catch {
            subject.send(previous)
        }
        return true
    }

    private func refreshItems() {
        do {
            subject.send(try store.fetchAll())
        } catch {
            subject.send([])
        }
    }

    private func restoreFromSnapshot(_ items: [ToSellItem]) {
        deletedStack.removeLast()
        subject.send(items)
    }
}
