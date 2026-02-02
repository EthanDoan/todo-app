import Combine
import Foundation

final class ToSellViewModel: ObservableObject {
    @Published private(set) var items: [ToSellItem] = []

    private let observeItemsUseCase: ObserveToSellItemsUseCase
    private let mutateUseCase: MutateToSellItemUseCase
    private var cancellables = Set<AnyCancellable>()

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

    func addSample() {
        try? mutateUseCase.add(title: "Sample", price: 10)
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            mutateUseCase.delete(id: items[index].id)
        }
    }

    func undoDelete() {
        _ = mutateUseCase.undoDelete()
    }
}
