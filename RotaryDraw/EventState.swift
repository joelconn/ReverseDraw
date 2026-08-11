import Foundation
import Observation

struct EventConfig: Codable {
    var numTickets: Int = 250
    var pricePerTicket: Double = 0.0
    var normalRevealDuration: Double = 5.0
    var winnerRevealDuration: Double = 12.0
    var threshold: Int = 240
    var specialPrizes: [String: Double] = [:]
    var bonusDrawAmount: Double = 0.0

    // Computed properties for prize money calculation
    var totalRevenue: Double { Double(numTickets) * pricePerTicket }
    var totalPrizePool: Double { totalRevenue * 0.5 }
    var specialPrizesTotal: Double {
        specialPrizes.values.reduce(0, +)
    }
    var totalTickets: Int { numTickets }
    var finalTenThreshold: Int { max(1, numTickets - 10) }
    var remainingPrizes: Double {
        max(0, totalPrizePool - specialPrizesTotal)
    }
    var finalTenPot: Double {
        max(0, totalPrizePool - specialPrizesTotal - bonusDrawAmount)
    }

    init() {}

    // Custom decode so old saved sessions missing newer fields still load.
    // Note: totalTickets, threshold, finalTenPot are now computed from numTickets,
    // bonusDrawAmount, and specialPrizes, so old persisted values are ignored.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        numTickets = try c.decodeIfPresent(Int.self, forKey: .numTickets) ?? 250
        pricePerTicket = try c.decodeIfPresent(Double.self, forKey: .pricePerTicket) ?? 0.0
        normalRevealDuration = try c.decodeIfPresent(Double.self, forKey: .normalRevealDuration) ?? 5.0
        winnerRevealDuration = try c.decodeIfPresent(Double.self, forKey: .winnerRevealDuration) ?? 12.0
        threshold = try c.decodeIfPresent(Int.self, forKey: .threshold) ?? (numTickets - 10)
        specialPrizes = try c.decodeIfPresent([String: Double].self, forKey: .specialPrizes) ?? [:]
        bonusDrawAmount = try c.decodeIfPresent(Double.self, forKey: .bonusDrawAmount) ?? 0.0
    }
}

// Alias to keep existing Snapshot compatibility
typealias Config = EventConfig

@Observable
final class EventState {
    var tickets: [Ticket] = []
    var drawHistory: [Int] = []
    var currentReveal: Int? = nil
    var lastRevealedTicketID: Int? = nil
    var phase: EventPhase = .setup
    var finalTenContestants: [Int] = []
    var eliminated: [Int] = []
    var config: EventConfig = EventConfig()
    var lastSavedAt: Date = Date()
    var guestList: [Int: GuestInfo] = [:]
    var carryoverPrize: Double? = nil
    var potSplitDone: Bool = false
    var eventName: String = ""

    private(set) var undoStack: [Snapshot] = []
    private let persistence: PersistenceManager

    // Captured right before startBonusDraw() resets all tickets, so the
    // final event archive can still report main-draw special prize winners
    // and the Final Ten draw order after the reset wipes the live ticket state.
    private var archiveDrawOrder: [EventArchive.DrawEntry] = []
    private var archiveSpecialPrizeWinners: [EventArchive.Winner] = []
    private var archiveFinalTenWinners: [EventArchive.Winner] = []

    // MARK: - Computed

    var canUndo: Bool { !undoStack.isEmpty }

    var remainingTickets: [Ticket] { tickets.filter { !$0.isDrawn } }

    var currentPotSplit: Double {
        guard finalTenContestants.count > 0 else { return config.finalTenPot }
        return config.finalTenPot / Double(finalTenContestants.count)
    }

    var revealTicket: Ticket? {
        guard let id = currentReveal else { return nil }
        return tickets.first { $0.id == id }
    }

    var currentRevealIsElimination: Bool {
        guard let id = currentReveal else { return false }
        return eliminated.contains(id)
    }

    var hasExistingSession: Bool {
        persistence.hasSession
    }

    // MARK: - Init

    init(persistence: PersistenceManager = .shared) {
        self.persistence = persistence
        resetTickets()
        guestList = persistence.loadGuestList()
        persistence.startAutoBackup { [weak self] in
            self?.makeSnapshot()
        }
    }

    // MARK: - Guest List

    func guest(for ticketID: Int) -> GuestInfo? {
        guestList[ticketID]
    }

    /// Parses a CSV string and stores the guest list, persisting it to disk.
    /// Returns the count of loaded entries.
    @discardableResult
    func loadGuestCSV(_ csvText: String) -> Int {
        let parsed = GuestInfo.parseCSV(csvText)
        guestList = parsed
        persistence.saveGuestList(parsed)
        return parsed.count
    }

    // MARK: - Configuration

    func configure(
        eventName: String,
        totalTickets: Int,
        prizes: [String: Double],
        normalDuration: Double,
        winnerDuration: Double,
        finalTenPot: Double,
        threshold: Int,
        bonusDrawAmount: Double
    ) {
        self.eventName = eventName
        config.numTickets = totalTickets
        config.specialPrizes = prizes
        config.normalRevealDuration = normalDuration
        config.winnerRevealDuration = winnerDuration
        config.bonusDrawAmount = bonusDrawAmount
        resetTickets()
        phase = .drawing
        drawHistory = []
        currentReveal = nil
        finalTenContestants = []
        eliminated = []
        undoStack = []
        carryoverPrize = nil
        potSplitDone = false
        autosave()
    }

    // MARK: - Actions

    func drawNextTicket() {
        guard phase == .drawing else { return }
        pushSnapshot()

        let undrawn = tickets.filter { !$0.isDrawn }
        guard let ticket = undrawn.randomElement() else { return }

        let drawPosition = drawHistory.count + 1
        if let i = tickets.firstIndex(where: { $0.id == ticket.id }) {
            tickets[i].isDrawn = true
            tickets[i].drawOrder = drawPosition
            if let carryover = carryoverPrize {
                tickets[i].isSpecialPrize = true
                tickets[i].prizeAmount = carryover
                carryoverPrize = nil
            } else if let prize = config.specialPrizes["\(drawPosition)"] {
                tickets[i].isSpecialPrize = true
                tickets[i].prizeAmount = prize
            }
        }
        drawHistory.append(ticket.id)
        currentReveal = ticket.id
        lastRevealedTicketID = ticket.id

        if drawHistory.count >= config.threshold {
            phase = .finalTen
            finalTenContestants = tickets.filter { !$0.isDrawn }.map { $0.id }.sorted()
        }

        autosave()
    }

    func clearReveal() {
        currentReveal = nil
        autosave()
    }

    func markNotPresent() {
        let revealID = currentReveal ?? lastRevealedTicketID
        guard let revealID else { return }
        pushSnapshot()
        if let i = tickets.firstIndex(where: { $0.id == revealID }) {
            if tickets[i].isSpecialPrize {
                carryoverPrize = tickets[i].prizeAmount
                tickets[i].isSpecialPrize = false
                tickets[i].prizeAmount = 0
            }
            tickets[i].wasNotPresent = true
        }
        currentReveal = nil
        lastRevealedTicketID = nil
        autosave()
    }

    func drawElimination() {
        guard phase == .finalTen, !potSplitDone,
              finalTenContestants.count > 1,
              let ticketID = finalTenContestants.randomElement() else { return }
        pushSnapshot()
        finalTenContestants.removeAll { $0 == ticketID }
        eliminated.append(ticketID)
        currentReveal = ticketID
        lastRevealedTicketID = ticketID
        autosave()
    }

    /// Ends the Final Ten elimination process and splits the pot evenly among
    /// whoever remains, regardless of count.
    func splitPot() {
        guard phase == .finalTen, !potSplitDone, currentReveal == nil,
              !finalTenContestants.isEmpty else { return }
        pushSnapshot()
        potSplitDone = true
        autosave()
    }

    func startBonusDraw() {
        guard phase == .finalTen, potSplitDone else { return }
        pushSnapshot()
        captureArchiveDataBeforeReset()
        resetTickets()
        phase = .bonusDraw
        drawHistory = []
        currentReveal = nil
        autosave()
    }

    func drawBonusTicket() {
        guard phase == .bonusDraw else { return }
        pushSnapshot()
        let undrawn = tickets.filter { !$0.isDrawn }
        guard let ticket = undrawn.randomElement() else { return }
        if let i = tickets.firstIndex(where: { $0.id == ticket.id }) {
            tickets[i].isDrawn = true
        }
        currentReveal = ticket.id
        phase = .complete
        autosave()
        saveEventArchive(grandWinnerTicketID: ticket.id)
    }

    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        restore(from: snapshot)
        autosave()
    }

    // MARK: - Session

    func startEvent() {
        configure(
            eventName: eventName,
            totalTickets: config.totalTickets,
            prizes: config.specialPrizes,
            normalDuration: config.normalRevealDuration,
            winnerDuration: config.winnerRevealDuration,
            finalTenPot: config.finalTenPot,
            threshold: config.threshold,
            bonusDrawAmount: config.bonusDrawAmount
        )
    }

    func recoverFromDrawnTickets(drawnIDs: [Int]) {
        guard !drawnIDs.isEmpty else { return }
        startEvent()
        for ticketID in drawnIDs {
            guard ticketID > 0, ticketID <= config.totalTickets else { continue }
            if let i = tickets.firstIndex(where: { $0.id == ticketID }) {
                let drawPosition = drawHistory.count + 1
                tickets[i].isDrawn = true
                tickets[i].drawOrder = drawPosition
                if let prize = config.specialPrizes["\(drawPosition)"] {
                    tickets[i].isSpecialPrize = true
                    tickets[i].prizeAmount = prize
                }
                drawHistory.append(ticketID)
            }
        }
        currentReveal = nil
        lastRevealedTicketID = nil
        if drawHistory.count >= config.threshold {
            phase = .finalTen
            finalTenContestants = tickets.filter { !$0.isDrawn }.map { $0.id }.sorted()
        }
        autosave()
    }

    @discardableResult
    func loadSession() -> Bool {
        guard let snapshot = persistence.load() else { return false }
        restore(from: snapshot)
        return true
    }

    func reset() {
        drawHistory = []
        currentReveal = nil
        lastRevealedTicketID = nil
        phase = .setup
        finalTenContestants = []
        eliminated = []
        undoStack = []
        config = EventConfig()
        carryoverPrize = nil
        potSplitDone = false
        eventName = ""
        resetTickets()
        persistence.clear()
    }

    // MARK: - Private

    private func resetTickets() {
        tickets = (1...max(config.totalTickets, 1)).map { Ticket(id: $0) }
    }

    /// Snapshots draw order, main-draw special prize winners, and Final Ten
    /// split winners right before startBonusDraw() wipes ticket state via resetTickets().
    private func captureArchiveDataBeforeReset() {
        archiveDrawOrder = drawHistory.enumerated().compactMap { index, ticketID in
            guard let ticket = tickets.first(where: { $0.id == ticketID }) else { return nil }
            return EventArchive.DrawEntry(
                drawPosition: index + 1,
                ticketID: ticketID,
                guestName: guest(for: ticketID)?.name,
                wasNotPresent: ticket.wasNotPresent,
                isSpecialPrize: ticket.isSpecialPrize,
                prizeAmount: ticket.prizeAmount
            )
        }

        archiveSpecialPrizeWinners = tickets
            .filter { $0.isSpecialPrize && $0.prizeAmount > 0 }
            .map { EventArchive.Winner(ticketID: $0.id, guestName: guest(for: $0.id)?.name, amount: $0.prizeAmount) }

        let splitAmount = currentPotSplit
        archiveFinalTenWinners = potSplitDone
            ? finalTenContestants.map { EventArchive.Winner(ticketID: $0, guestName: guest(for: $0)?.name, amount: splitAmount) }
            : []
    }

    private func saveEventArchive(grandWinnerTicketID: Int) {
        let grandWinner = EventArchive.Winner(
            ticketID: grandWinnerTicketID,
            guestName: guest(for: grandWinnerTicketID)?.name,
            amount: config.bonusDrawAmount
        )
        let archive = EventArchive(
            eventName: eventName.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled Event" : eventName,
            date: Date(),
            totalTickets: config.totalTickets,
            drawOrder: archiveDrawOrder,
            specialPrizeWinners: archiveSpecialPrizeWinners,
            finalTenWinners: archiveFinalTenWinners,
            grandPrizeWinner: grandWinner
        )
        persistence.saveEventArchive(archive)
    }

    private func pushSnapshot() {
        undoStack.append(makeSnapshot())
        if undoStack.count > 20 { undoStack.removeFirst() }
    }

    func makeSnapshot() -> Snapshot {
        Snapshot(
            tickets: tickets,
            drawHistory: drawHistory,
            currentReveal: currentReveal,
            phase: phase,
            finalTenContestants: finalTenContestants,
            eliminated: eliminated,
            config: config,
            timestamp: Date(),
            carryoverPrize: carryoverPrize,
            potSplitDone: potSplitDone,
            eventName: eventName
        )
    }

    private func restore(from snapshot: Snapshot) {
        tickets = snapshot.tickets
        drawHistory = snapshot.drawHistory
        currentReveal = snapshot.currentReveal
        phase = snapshot.phase
        finalTenContestants = snapshot.finalTenContestants
        eliminated = snapshot.eliminated
        config = snapshot.config
        carryoverPrize = snapshot.carryoverPrize
        potSplitDone = snapshot.potSplitDone ?? false
        eventName = snapshot.eventName ?? ""
    }

    private func autosave() {
        let snapshot = makeSnapshot()
        persistence.save(snapshot)
        lastSavedAt = Date()
    }
}
