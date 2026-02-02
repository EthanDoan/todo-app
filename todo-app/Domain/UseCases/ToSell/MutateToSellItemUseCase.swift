protocol MutateToSellItemUseCase {
    func add(title: String, price: Decimal) throws
    func update(item: ToSellItem) throws
    func delete(id: UUID)
    func bulkDelete(ids: [UUID])
    func undoDelete() -> Bool
}

struct DefaultMutateToSellItemUseCase: MutateToSellItemUseCase {
    let repository: ToSellRepository

    func add(title: String, price: Decimal) throws {
        try repository.addItem(title: title, price: price)
    }

    func update(item: ToSellItem) throws {
        try repository.updateItem(item)
    }

    func delete(id: UUID) {
        repository.deleteItem(id: id)
    }

    func bulkDelete(ids: [UUID]) {
        repository.bulkDelete(ids: ids)
    }

    func undoDelete() -> Bool {
        repository.undoDelete()
    }
}
