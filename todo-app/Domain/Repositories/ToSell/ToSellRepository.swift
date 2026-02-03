import Combine
import Foundation

protocol ToSellRepository {
    var itemsPublisher: AnyPublisher<[ToSellItem], Never> { get }
    func addItem(title: String, price: Decimal, isSold: Bool) throws
    func updateItem(_ item: ToSellItem) throws
    func deleteItem(id: UUID)
    func bulkDelete(ids: [UUID])
    func undoDelete() -> Bool
}
