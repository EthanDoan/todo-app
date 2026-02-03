import Combine
import Foundation

final class ToSellViewModel: ObservableObject {
    @Published private(set) var items: [ToSellItem] = []
    @Published var errorMessage: String?
    @Published private(set) var canUndoDelete = false

    private let observeItemsUseCase: ObserveToSellItemsUseCase
    private let mutateUseCase: MutateToSellItemUseCase
    private var cancellables = Set<AnyCancellable>()
    private var undoDepth = 0

    init(observeItemsUseCase: ObserveToSellItemsUseCase, mutateUseCase: MutateToSellItemUseCase) {
        self.observeItemsUseCase = observeItemsUseCase
        self.mutateUseCase = mutateUseCase
        bind()
    }

    private func bind() {
        observeItemsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }

    @discardableResult
    func addItem(title: String, priceText: String, isSold: Bool) -> Bool {
        do {
            let price = try parsePrice(from: priceText)
            try mutateUseCase.add(title: title, price: price, isSold: isSold)
            errorMessage = nil
            return true
        } catch let error as ToSellValidationError {
            errorMessage = error.message
        } catch {
            errorMessage = "Please enter a valid price."
        }
        return false
    }

    @discardableResult
    func updateItem(id: UUID, title: String, priceText: String, isSold: Bool) -> Bool {
        do {
            let price = try parsePrice(from: priceText)
            try mutateUseCase.update(item: ToSellItem(id: id, title: title, price: price, isSold: isSold))
            errorMessage = nil
            return true
        } catch let error as ToSellValidationError {
            errorMessage = error.message
        } catch {
            errorMessage = "Please enter a valid price."
        }
        return false
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { items[$0].id }
        bulkDelete(ids: ids)
    }

    func bulkDelete(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        mutateUseCase.bulkDelete(ids: ids)
        undoDepth += 1
        canUndoDelete = undoDepth > 0
    }

    func undoDelete() {
        let didUndo = mutateUseCase.undoDelete()
        if didUndo {
            undoDepth = max(undoDepth - 1, 0)
        }
        canUndoDelete = undoDepth > 0
    }

    private func parsePrice(from priceText: String) throws -> Decimal {
        let trimmed = priceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Decimal(string: trimmed, locale: .current) else {
            throw ToSellValidationError(message: "Price is required")
        }
        return value
    }
}
