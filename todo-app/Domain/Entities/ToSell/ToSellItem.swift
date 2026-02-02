import Foundation

struct ToSellItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let price: Decimal
    let isSold: Bool
}

struct ToSellValidationError: Error, Equatable {
    let message: String
}
