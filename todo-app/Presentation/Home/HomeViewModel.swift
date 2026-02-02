import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    @Published private(set) var counters: HomeCounters = .zero

    private let observeCountersUseCase: ObserveHomeCountersUseCase
    private let startUpdatesUseCase: StartHomeCountersUpdatesUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        observeCountersUseCase: ObserveHomeCountersUseCase,
        startUpdatesUseCase: StartHomeCountersUpdatesUseCase
    ) {
        self.observeCountersUseCase = observeCountersUseCase
        self.startUpdatesUseCase = startUpdatesUseCase
        bind()
    }

    private func bind() {
        startUpdatesUseCase.execute()
        observeCountersUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] counters in
                self?.counters = counters
            }
            .store(in: &cancellables)
    }
}
