import Combine
import Foundation

final class LocalToSellRepository: ToSellRepository {
    private let subject = CurrentValueSubject<[ToSellItem], Never>([])
    private var deletedStack: [[ToSellItem]] = []

    var itemsPublisher: AnyPublisher<[ToSellItem], Never> {
        subject.eraseToAnyPublisher()
    }

    func addItem(title: String, price: Decimal) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ToSellValidationError(message: "Title is required")
        }
        let item = ToSellItem(id: UUID(), title: title, price: price, isSold: false)
        subject.send(subject.value + [item])
    }

    func updateItem(_ item: ToSellItem) throws {
        guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ToSellValidationError(message: "Title is required")
        }
        let updated = subject.value.map { existing in
            existing.id == item.id ? item : existing
        }
        subject.send(updated)
    }

    func deleteItem(id: UUID) {
        let items = subject.value
        deletedStack.append(items)
        subject.send(items.filter { $0.id != id })
    }

    func bulkDelete(ids: [UUID]) {
        let items = subject.value
        deletedStack.append(items)
        let set = Set(ids)
        subject.send(items.filter { !set.contains($0.id) })
    }

    func undoDelete() -> Bool {
        guard let previous = deletedStack.popLast() else {
            return false
        }
        subject.send(previous)
        return true
    }
}
