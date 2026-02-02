import Foundation

struct SellSyncItem: Identifiable, Equatable {
    let id: UUID
    let itemId: UUID
    let soldAt: Date
    let syncedAt: Date?
}
