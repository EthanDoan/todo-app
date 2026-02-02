protocol UpdateToCallCountUseCase {
    func execute(count: Int)
}

struct DefaultUpdateToCallCountUseCase: UpdateToCallCountUseCase {
    let repository: HomeCounterRepository

    func execute(count: Int) {
        repository.updateToCallCount(count)
    }
}
