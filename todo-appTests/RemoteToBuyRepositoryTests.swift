import Combine
import XCTest

@testable import todo_app

final class RemoteToBuyRepositoryTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testFetchItemsAppliesWishlistAndMergesStoreItems() {
        let fetchedId = UUID()
        let existingId = UUID()
        let fetchedItem = ToBuyItem(id: fetchedId, title: "Fetched", price: 10, isWishlisted: false)
        let existingItem = ToBuyItem(id: existingId, title: "Existing", price: 20, isWishlisted: false)

        let apiClient = ToBuyAPIClientStub()
        apiClient.fetchItemsResult = .success([fetchedItem])

        let wishlistStore = WishlistStoreStub()
        wishlistStore.loadWishlistResult = .success([fetchedId])

        let store = InMemoryToBuyStore()
        store.updateItems([existingItem])

        let repository = RemoteToBuyRepository(apiClient: apiClient, wishlistStore: wishlistStore, store: store)
        let expectation = expectation(description: "fetch items")

        var receivedItems: [ToBuyItem] = []
        repository.fetchItems(sort: .priceAscending, filter: ToBuyFilter(searchText: nil, maxPrice: nil))
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            }, receiveValue: { items in
                receivedItems = items
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)

        let expectedFetched = ToBuyItem(id: fetchedId, title: "Fetched", price: 10, isWishlisted: true)
        XCTAssertEqual(receivedItems, [expectedFetched])
        XCTAssertEqual(store.currentItems(), [expectedFetched, existingItem])
    }

    func testFetchDetailAppliesWishlistFlag() {
        let itemId = UUID()
        let detail = ToBuyItemDetail(
            id: itemId,
            title: "Detail",
            description: "Description",
            price: 44,
            isWishlisted: false
        )

        let apiClient = ToBuyAPIClientStub()
        apiClient.fetchDetailResult = .success(detail)

        let wishlistStore = WishlistStoreStub()
        wishlistStore.loadWishlistResult = .success([itemId])

        let repository = RemoteToBuyRepository(
            apiClient: apiClient,
            wishlistStore: wishlistStore,
            store: InMemoryToBuyStore()
        )
        let expectation = expectation(description: "fetch detail")

        var receivedDetail: ToBuyItemDetail?
        repository.fetchDetail(id: itemId)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            }, receiveValue: { detail in
                receivedDetail = detail
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(
            receivedDetail,
            ToBuyItemDetail(
                id: itemId,
                title: "Detail",
                description: "Description",
                price: 44,
                isWishlisted: true
            )
        )
    }

    func testSetWishlistUpdatesStore() {
        let itemId = UUID()
        let store = InMemoryToBuyStore()
        store.updateItems([ToBuyItem(id: itemId, title: "Item", price: 12, isWishlisted: false)])

        let wishlistStore = WishlistStoreStub()
        wishlistStore.setWishlistResult = .success(true)

        let repository = RemoteToBuyRepository(
            apiClient: ToBuyAPIClientStub(),
            wishlistStore: wishlistStore,
            store: store
        )
        let expectation = expectation(description: "set wishlist")

        repository.setWishlist(id: itemId, isWishlisted: true)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            }, receiveValue: { _ in
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(
            store.currentItems(),
            [ToBuyItem(id: itemId, title: "Item", price: 12, isWishlisted: true)]
        )
    }

    func testObserveNewItemsAppendsToStore() {
        let store = InMemoryToBuyStore()
        let apiClient = ToBuyAPIClientStub()
        let repository = RemoteToBuyRepository(
            apiClient: apiClient,
            wishlistStore: WishlistStoreStub(),
            store: store
        )

        _ = repository

        let expectation = expectation(description: "realtime item appended")
        store.itemsPublisher
            .dropFirst()
            .sink { items in
                if items.count == 1, items.first?.title == "Realtime" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        apiClient.newItemsSubject.send(
            ToBuyItem(id: UUID(), title: "Realtime", price: 9, isWishlisted: false)
        )

        waitForExpectations(timeout: 1)
    }
}

private final class ToBuyAPIClientStub: ToBuyAPIClientProtocol {
    var fetchItemsResult: Result<[ToBuyItem], Error> = .success([])
    var fetchDetailResult: Result<ToBuyItemDetail, Error> = .success(
        ToBuyItemDetail(id: UUID(), title: "", description: "", price: 0, isWishlisted: false)
    )
    let newItemsSubject = PassthroughSubject<ToBuyItem, Never>()

    func fetchItems(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error> {
        fetchItemsResult.publisher.eraseToAnyPublisher()
    }

    func fetchDetail(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error> {
        fetchDetailResult.publisher.eraseToAnyPublisher()
    }

    func observeNewItems() -> AnyPublisher<ToBuyItem, Never> {
        newItemsSubject.eraseToAnyPublisher()
    }
}

private final class WishlistStoreStub: WishlistStoreProtocol {
    var loadWishlistResult: Result<[UUID], Error> = .success([])
    var setWishlistResult: Result<Bool, Error> = .success(true)

    func loadWishlist() -> AnyPublisher<[UUID], Error> {
        loadWishlistResult.publisher.eraseToAnyPublisher()
    }

    func setWishlist(id: UUID, isWishlisted: Bool) -> AnyPublisher<Bool, Error> {
        setWishlistResult.publisher.eraseToAnyPublisher()
    }
}
