import Foundation

struct Snapshot: Codable {
    var tickets: [Ticket]
    var drawHistory: [Int]
    var currentReveal: Int?
    var phase: EventPhase
    var finalTenContestants: [Int]
    var eliminated: [Int]
    var config: Config
    let timestamp: Date
    var carryoverPrize: Double?
    var potSplitDone: Bool?
    var eventName: String?
}
