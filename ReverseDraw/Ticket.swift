import Foundation

struct Ticket: Codable, Identifiable, Equatable {
    let id: Int
    var isDrawn: Bool = false
    var isSpecialPrize: Bool = false
    var prizeAmount: Double = 0
    var drawOrder: Int? = nil
    var wasNotPresent: Bool = false
    var isUnused: Bool = false
}
