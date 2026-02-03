protocol UpdateToSellCountUseCase {
    func execute(count: Int)
}

struct DefaultUpdateToSellCountUseCase: UpdateToSellCountUseCase {
    let repository: HomeCounterRepository

    func execute(count: Int) {
        repository.updateToSellCount(count)
    }
}
