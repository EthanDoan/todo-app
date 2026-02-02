import Combine

protocol RetryToCallUseCase {
    func execute() -> AnyPublisher<ToCallPage, Error>
}

struct DefaultRetryToCallUseCase: RetryToCallUseCase {
    let repository: ToCallRepository

    func execute() -> AnyPublisher<ToCallPage, Error> {
        repository.retryLastRequest()
    }
}
