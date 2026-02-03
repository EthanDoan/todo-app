protocol UpdateToBuyCountUseCase {
    func execute(count: Int)
}

struct DefaultUpdateToBuyCountUseCase: UpdateToBuyCountUseCase {
    let repository: HomeCounterRepository

    func execute(count: Int) {
        repository.updateToBuyCount(count)
    }
}
