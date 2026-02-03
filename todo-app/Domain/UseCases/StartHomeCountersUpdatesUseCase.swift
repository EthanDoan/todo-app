protocol StartHomeCountersUpdatesUseCase {
    func execute()
}

struct DefaultStartHomeCountersUpdatesUseCase: StartHomeCountersUpdatesUseCase {
    let repository: HomeCounterRepository

    func execute() {
        
    }
}
