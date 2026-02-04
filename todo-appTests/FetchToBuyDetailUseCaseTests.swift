import Combine
import XCTest

@testable import todo_app

final class FetchToBuyDetailUseCaseTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testExecuteReturnsRepositoryDetail() {
        let id = UUID()
        let expectedDetail = ToBuyItemDetail(
            id: id,
            title: "Coffee Grinder",
            description: "Burr grinder",
            price: 129.99,
            isWishlisted: true
        )
        let repository = ToBuyRepositoryStub()
        repository.fetchDetailHandler = { requestedID in
            XCTAssertEqual(requestedID, id)
            return Just(expectedDetail)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        let useCase = DefaultFetchToBuyDetailUseCase(repository: repository)
        let expectation = expectation(description: "Returns detail")

        useCase.execute(id: id)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            }, receiveValue: { detail in
                XCTAssertEqual(detail, expectedDetail)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testExecutePropagatesRepositoryError() {
        enum TestError: Error, Equatable {
            case failure
        }

        let id = UUID()
        let repository = ToBuyRepositoryStub()
        repository.fetchDetailHandler = { _ in
            Fail(error: TestError.failure)
                .eraseToAnyPublisher()
        }
        let useCase = DefaultFetchToBuyDetailUseCase(repository: repository)
        let expectation = expectation(description: "Propagates error")

        useCase.execute(id: id)
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

private final class ToBuyRepositoryStub: ToBuyRepository {
    var fetchDetailHandler: (UUID) -> AnyPublisher<ToBuyItemDetail, Error> = { _ in
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }

    func fetchItems(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error> {
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }

    func fetchDetail(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error> {
        fetchDetailHandler(id)
    }

    func setWishlist(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error> {
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }

    func loadWishlist() -> AnyPublisher<[UUID], Error> {
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }

    func observeItems() -> AnyPublisher<[ToBuyItem], Never> {
        Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }
}
