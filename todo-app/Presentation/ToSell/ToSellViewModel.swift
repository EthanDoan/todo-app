import Combine
import Foundation

final class ToSellViewModel: ObservableObject {
    @Published private(set) var items: [ToSellItem] = []
    @Published var selection = Set<UUID>()
    @Published var isPresentingEditor = false
    @Published var editorTitle = ""
    @Published var editorPrice = ""
    @Published var isShowingError = false
    @Published private(set) var errorMessage = ""

    private var editingItem: ToSellItem?

    private let observeItemsUseCase: ObserveToSellItemsUseCase
    private let mutateUseCase: MutateToSellItemUseCase
    private let updateToSellCountUseCase: UpdateToSellCountUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        observeItemsUseCase: ObserveToSellItemsUseCase,
        mutateUseCase: MutateToSellItemUseCase,
        updateToSellCountUseCase: UpdateToSellCountUseCase
    ) {
        self.observeItemsUseCase = observeItemsUseCase
        self.mutateUseCase = mutateUseCase
        self.updateToSellCountUseCase = updateToSellCountUseCase
        bind()
    }

    private func bind() {
        observeItemsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
                let pendingCount = items.filter { !$0.isSold }.count
                self?.updateToSellCountUseCase.execute(count: pendingCount)
            }
            .store(in: &cancellables)
    }

    func startAdd() {
        editingItem = nil
        editorTitle = ""
        editorPrice = ""
        isPresentingEditor = true
    }

    func startEdit(item: ToSellItem) {
        editingItem = item
        editorTitle = item.title
        editorPrice = item.price.description
        isPresentingEditor = true
    }

    func save() {
        let trimmedTitle = editorTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let price = Decimal(string: editorPrice.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            presentError(message: "Price must be a valid number.")
            return
        }

        do {
            if let editingItem {
                let updated = ToSellItem(id: editingItem.id, title: trimmedTitle, price: price, isSold: editingItem.isSold)
                try mutateUseCase.update(item: updated)
            } else {
                try mutateUseCase.add(title: trimmedTitle, price: price)
            }
            isPresentingEditor = false
        } catch let error as ToSellValidationError {
            presentError(message: error.message)
        } catch {
            presentError(message: "Something went wrong. Please try again.")
        }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            mutateUseCase.delete(id: items[index].id)
        }
    }

    func deleteItem(id: UUID) {
        mutateUseCase.delete(id: id)
    }

    func toggleSold(item: ToSellItem, isSold: Bool) {
        let updated = ToSellItem(id: item.id, title: item.title, price: item.price, isSold: isSold)
        do {
            try mutateUseCase.update(item: updated)
        } catch let error as ToSellValidationError {
            presentError(message: error.message)
        } catch {
            presentError(message: "Something went wrong. Please try again.")
        }
    }

    func bulkDeleteSelection() {
        let ids = Array(selection)
        guard !ids.isEmpty else { return }
        mutateUseCase.bulkDelete(ids: ids)
        selection.removeAll()
    }

    func undoDelete() {
        if !mutateUseCase.undoDelete() {
            presentError(message: "Nothing to undo.")
        }
    }

    private func presentError(message: String) {
        errorMessage = message
        isShowingError = true
    }
}
