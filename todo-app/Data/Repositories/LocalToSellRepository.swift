import Combine
import Foundation

final class LocalToSellRepository: ToSellRepository {
    private let store: SQLiteItemToSellStore
    private let subject: CurrentValueSubject<[ToSellItem], Never>
    private var deletedStack: [[ToSellItem]] = []

    init(store: SQLiteItemToSellStore) {
        self.store = store
        let items = (try? store.fetchAll()) ?? []
        self.subject = CurrentValueSubject(items)
    }

    var itemsPublisher: AnyPublisher<[ToSellItem], Never> {
        subject.eraseToAnyPublisher()
    }

    func addItem(title: String, price: Decimal, isSold: Bool) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ToSellValidationError(message: "Title is required")
        }
        guard price >= 0 else {
            throw ToSellValidationError(message: "Price must be zero or greater")
        }
        let item = ToSellItem(id: UUID(), title: title, price: price, isSold: isSold)
        try store.insert(item: item)
        reload()
    }

    func updateItem(_ item: ToSellItem) throws {
        guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ToSellValidationError(message: "Title is required")
        }
        guard item.price >= 0 else {
            throw ToSellValidationError(message: "Price must be zero or greater")
        }
        try store.update(item: item)
        reload()
    }

    func deleteItem(id: UUID) {
        let items = subject.value
        deletedStack.append(items)
        do {
            try store.delete(id: id)
            reload()
        } catch {
            deletedStack.removeLast()
        }
    }

    func bulkDelete(ids: [UUID]) {
        let items = subject.value
        deletedStack.append(items)
        do {
            try store.delete(ids: ids)
            reload()
        } catch {
            deletedStack.removeLast()
        }
    }

    func undoDelete() -> Bool {
        guard let previous = deletedStack.popLast() else {
            return false
        }
        do {
            try store.replaceAll(items: previous)
            reload()
            return true
        } catch {
            deletedStack.append(previous)
            return false
        }
    }

    private func reload() {
        let items = (try? store.fetchAll()) ?? []
        subject.send(items)
    }
}
