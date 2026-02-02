import Foundation

struct ToCallPage: Equatable {
    let items: [ToCallPerson]
    let nextPage: Int?
    let lastSyncedAt: Date?
}

struct ToCallFilter: Equatable {
    let searchText: String?
}
