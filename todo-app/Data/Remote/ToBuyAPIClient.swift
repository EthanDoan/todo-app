import Combine
import Foundation

final class ToBuyAPIClient {
    func fetchItems(sort: ToBuySortOption, filter: ToBuyFilter) -> AnyPublisher<[ToBuyItem], Error> {
        Deferred {
            Future { promise in
                do {
                    let items = try Self.loadMockItems()
                    let filtered = items
                        .filter { item in
                            let matchesSearch: Bool
                            if let searchText = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines),
                               !searchText.isEmpty {
                                let normalized = searchText.lowercased()
                                matchesSearch = item.title.lowercased().contains(normalized)
                                    || item.description.lowercased().contains(normalized)
                            } else {
                                matchesSearch = true
                            }

                            let matchesPrice: Bool
                            if let maxPrice = filter.maxPrice {
                                matchesPrice = Decimal(item.price) <= maxPrice
                            } else {
                                matchesPrice = true
                            }
                            return matchesSearch && matchesPrice
                        }
                    let sorted = Self.sort(items: filtered, sort: sort)
                    let mapped = sorted.map { item in
                        ToBuyItem(id: item.id, title: item.title, price: Decimal(item.price), isWishlisted: false)
                    }
                    promise(.success(mapped))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchDetail(id: UUID) -> AnyPublisher<ToBuyItemDetail, Error> {
        Deferred {
            Future { promise in
                do {
                    let items = try Self.loadMockItems()
                    guard let item = items.first(where: { $0.id == id }) else {
                        return promise(.failure(ToBuyAPIError.itemNotFound))
                    }
                    let detail = ToBuyItemDetail(
                        id: item.id,
                        title: item.title,
                        description: item.description,
                        price: Decimal(item.price),
                        isWishlisted: false
                    )
                    promise(.success(detail))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func observeNewItems() -> AnyPublisher<ToBuyItem, Never> {
        Timer.publish(every: 8, on: .main, in: .common)
            .autoconnect()
            .scan(0) { index, _ in index + 1 }
            .map { index in
                let item = Self.realtimeItems[index % Self.realtimeItems.count]
                return ToBuyItem(
                    id: UUID(),
                    title: item.title,
                    price: item.price,
                    isWishlisted: false
                )
            }
            .eraseToAnyPublisher()
    }
}

private enum ToBuyAPIError: Error {
    case itemNotFound
}

private struct ToBuyMockResponse: Decodable {
    let items: [ToBuyMockItem]
}

private struct ToBuyMockItem: Decodable {
    let id: UUID
    let title: String
    let description: String
    let price: Double
    let category: String
}

private extension ToBuyAPIClient {
    struct ToBuyRealtimeItem {
        let title: String
        let price: Decimal
    }

    static func loadMockItems() throws -> [ToBuyMockItem] {
        let data = Data(mockPayload.utf8)
        let response = try JSONDecoder().decode(ToBuyMockResponse.self, from: data)
        return response.items
    }

    static func sort(items: [ToBuyMockItem], sort: ToBuySortOption) -> [ToBuyMockItem] {
        switch sort {
        case .priceAscending:
            return items.sorted { $0.price < $1.price }
        case .priceDescending:
            return items.sorted { $0.price > $1.price }
        case .titleAscending:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    static let mockPayload = """
    {
      "items": [
        {
          "id": "94A58B56-3D96-4F87-8B6B-1CC2A6D6F5ED",
          "title": "Reusable Water Bottle",
          "description": "Insulated stainless steel bottle that keeps drinks cold for 24 hours.",
          "price": 24.99,
          "category": "Kitchen"
        },
        {
          "id": "5B96A5E9-6A66-4A4D-9C3D-9D0DAF272C6D",
          "title": "Noise Cancelling Headphones",
          "description": "Over-ear wireless headphones with active noise cancellation and 30-hour battery.",
          "price": 199.00,
          "category": "Electronics"
        },
        {
          "id": "B1E1E9F9-10F4-4B4B-99B7-2D2DAE8DD8F4",
          "title": "Desk Organizer Set",
          "description": "Modular desk organizer with trays, pen holder, and cable clips.",
          "price": 32.50,
          "category": "Office"
        },
        {
          "id": "D7D4C61B-7E5E-470A-92BE-514C2B0E6C3D",
          "title": "Smart LED Light Bulb",
          "description": "Dimmable LED bulb with app control and adjustable color temperature.",
          "price": 18.75,
          "category": "Home"
        },
        {
          "id": "3F9EFA12-7E2D-4C86-A8E1-2A0C5C5D1E42",
          "title": "Yoga Mat",
          "description": "Non-slip yoga mat with extra cushioning and carrying strap.",
          "price": 41.20,
          "category": "Fitness"
        },
        {
          "id": "6B7E84A8-915A-4B7E-8E8A-8F7C57E1F02D",
          "title": "Coffee Grinder",
          "description": "Electric burr grinder with 18 grind settings for fresh coffee.",
          "price": 68.40,
          "category": "Kitchen"
        }
      ]
    }
    """

    static let realtimeItems: [ToBuyRealtimeItem] = [
        ToBuyRealtimeItem(title: "Portable Phone Charger", price: 29.99),
        ToBuyRealtimeItem(title: "Smart Notebook", price: 16.40),
        ToBuyRealtimeItem(title: "Compact Bluetooth Speaker", price: 45.90)
    ]
}
