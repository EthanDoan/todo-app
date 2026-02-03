import Foundation

protocol FetchCachedToCallPageUseCase {
    func execute(page: Int, filter: ToCallFilter) -> ToCallPage
}

struct DefaultFetchCachedToCallPageUseCase: FetchCachedToCallPageUseCase {
    let repository: ToCallCacheRepository

    func execute(page: Int, filter: ToCallFilter) -> ToCallPage {
        repository.page(page: page, filter: filter)
    }
}
