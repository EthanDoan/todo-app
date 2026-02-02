import Foundation

struct ToBuyItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let price: Decimal
    let isWishlisted: Bool
}

struct ToBuyItemDetail: Equatable {
    let id: UUID
    let title: String
    let description: String
    let price: Decimal
    let isWishlisted: Bool
}

enum ToBuySortOption: Equatable {
    case priceAscending
    case priceDescending
    case titleAscending
}

struct ToBuyFilter: Equatable {
    let searchText: String?
    let maxPrice: Decimal?
}
