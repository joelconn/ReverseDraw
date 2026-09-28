import Foundation

/// Permanent record of a completed event, written to disk once the bonus/grand
/// prize draw finishes. Unlike Snapshot (live undo/resume state), this is never
/// overwritten — one file per event, kept for record-keeping.
struct EventArchive: Codable {
    struct DrawEntry: Codable {
        let drawPosition: Int
        let ticketID: Int
        let guestName: String?
        let wasNotPresent: Bool
        let isSpecialPrize: Bool
        let prizeAmount: Double
    }

    struct Winner: Codable {
        let ticketID: Int
        let guestName: String?
        let amount: Double
    }

    let eventName: String
    let date: Date
    let totalTickets: Int
    let drawOrder: [DrawEntry]
    let specialPrizeWinners: [Winner]
    let finalTenWinners: [Winner]
    let grandPrizeWinner: Winner?
}
