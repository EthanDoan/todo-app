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

enum ToBuySortOption: String, CaseIterable, Equatable {
    case priceAscending
    case priceDescending
    case titleAscending

    var label: String {
        switch self {
        case .priceAscending:
            return "Price: Low to High"
        case .priceDescending:
            return "Price: High to Low"
        case .titleAscending:
            return "Title"
        }
    }
}

struct ToBuyFilter: Equatable {
    let searchText: String?
    let maxPrice: Decimal?
}
