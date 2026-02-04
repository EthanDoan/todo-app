import Combine
import XCTest

@testable import todo_app

final class FetchToCallPageUseCaseTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testExecuteReturnsRepositoryPage() {
        let expectedPage = ToCallPage(
            items: [
                ToCallPerson(
                    id: UUID(),
                    name: "Alex",
                    phoneNumber: "555-1234",
                    lastSyncedAt: Date()
                )
            ],
            nextPage: 2,
            lastSyncedAt: Date()
        )
        let repository = ToCallRepositoryStub()
        let expectedPageNumber = 1
        let expectedFilter = ToCallFilter(searchText: "a")
        repository.fetchPeopleHandler = { page, filter in
            XCTAssertEqual(page, expectedPageNumber)
            XCTAssertEqual(filter, expectedFilter)
            return Just(expectedPage)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        let useCase = DefaultFetchToCallPageUseCase(repository: repository)
        let expectation = expectation(description: "Returns page")

        useCase.execute(page: expectedPageNumber, filter: expectedFilter)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            }, receiveValue: { page in
                XCTAssertEqual(page, expectedPage)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testExecutePropagatesRepositoryError() {
        enum TestError: Error, Equatable {
            case failure
        }

        let repository = ToCallRepositoryStub()
        repository.fetchPeopleHandler = { _, _ in
            Fail(error: TestError.failure)
                .eraseToAnyPublisher()
        }
        let useCase = DefaultFetchToCallPageUseCase(repository: repository)
        let expectation = expectation(description: "Propagates error")

        useCase.execute(page: 3, filter: ToCallFilter(searchText: nil))
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertTrue(error is TestError)
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected error, received value")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}

private final class ToCallRepositoryStub: ToCallRepository {
    var fetchPeopleHandler: (Int, ToCallFilter) -> AnyPublisher<ToCallPage, Error> = { _, _ in
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }

    func fetchPeople(page: Int, filter: ToCallFilter) -> AnyPublisher<ToCallPage, Error> {
        fetchPeopleHandler(page, filter)
    }

    func retryLastRequest() -> AnyPublisher<ToCallPage, Error> {
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }

    func observeUpdates() -> AnyPublisher<[ToCallPerson], Never> {
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }

    func observeCount() -> AnyPublisher<Int, Never> {
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }
}
