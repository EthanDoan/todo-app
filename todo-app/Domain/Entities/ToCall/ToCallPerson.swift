import Foundation

struct ToCallPerson: Identifiable, Equatable {
    let id: UUID
    let name: String
    let phoneNumber: String
    let lastSyncedAt: Date?
}
