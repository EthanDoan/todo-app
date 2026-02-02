import Foundation

struct HomeCounters: Equatable {
    let toCall: Int
    let toBuy: Int
    let toSell: Int
    let sync: Int

    static let zero = HomeCounters(toCall: 0, toBuy: 0, toSell: 0, sync: 0)
}
