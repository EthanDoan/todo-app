import Combine
import Foundation

final class ToBuyDetailViewModel: ObservableObject {
    @Published private(set) var detail: ToBuyItemDetail?
    @Published private(set) var isLoading = false

    private let id: UUID
    private let fetchDetailUseCase: FetchToBuyDetailUseCase
    private let setWishlistUseCase: SetWishlistUseCase
    private var cancellables = Set<AnyCancellable>()

    init(id: UUID, fetchDetailUseCase: FetchToBuyDetailUseCase, setWishlistUseCase: SetWishlistUseCase) {
        self.id = id
        self.fetchDetailUseCase = fetchDetailUseCase
        self.setWishlistUseCase = setWishlistUseCase
    }

    func load() {
        isLoading = true
        fetchDetailUseCase.execute(id: id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] detail in
                self?.detail = detail
            })
            .store(in: &cancellables)
    }

    func toggleWishlist() {
        guard let detail else { return }
        let newValue = !detail.isWishlisted
        setWishlistUseCase.execute(id: detail.id, isWishlisted: newValue)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                guard let self else { return }
                self.detail = ToBuyItemDetail(
                    id: detail.id,
                    title: detail.title,
                    description: detail.description,
                    price: detail.price,
                    isWishlisted: newValue
                )
            })
            .store(in: &cancellables)
    }
}
