import Foundation

protocol EnqueueSellSyncUseCase {
    func execute(itemId: UUID) throws
}

struct DefaultEnqueueSellSyncUseCase: EnqueueSellSyncUseCase {
    let repository: SyncRepository

    func execute(itemId: UUID) throws {
        try repository.markItemSold(id: itemId)
    }
}
