import Testing
import Foundation
@testable import RotaryDraw

@MainActor
struct EventStateTests {

    /// Each test gets an EventState backed by an isolated temp directory, so
    /// tests never touch the real ~/Library/Application Support/RotaryDraw/.
    private func makeState(
        totalTickets: Int = 10,
        threshold: Int = 8,
        finalTenPot: Double = 100,
        bonusDrawAmount: Double = 500
    ) -> EventState {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let persistence = PersistenceManager(directoryOverride: tempDir)
        let state = EventState(persistence: persistence)
        state.eventName = "Test Event"
        state.config.totalTickets = totalTickets
        state.config.threshold = threshold
        state.config.finalTenPot = finalTenPot
        state.config.bonusDrawAmount = bonusDrawAmount
        state.startEvent()
        return state
    }

    // MARK: - Drawing

    @Test func drawNextTicketMarksTicketDrawn() {
        let state = makeState()
        state.drawNextTicket()

        #expect(state.drawHistory.count == 1)
        #expect(state.currentReveal != nil)

        let ticket = state.tickets.first { $0.id == state.currentReveal }
        #expect(ticket?.isDrawn == true)
        #expect(ticket?.drawOrder == 1)
    }

    @Test func drawNextTicketIgnoredWhileRevealing() {
        let state = makeState()
        state.drawNextTicket()
        let firstReveal = state.currentReveal

        state.drawNextTicket()

        #expect(state.currentReveal == firstReveal)
        #expect(state.drawHistory.count == 1)
    }

    @Test func specialPrizeAssignedAtConfiguredDrawPosition() {
        let state = makeState()
        state.config.specialPrizes = ["1": 250.0]

        state.drawNextTicket()

        let ticket = state.tickets.first { $0.id == state.currentReveal }
        #expect(ticket?.isSpecialPrize == true)
        #expect(ticket?.prizeAmount == 250.0)
    }

    @Test func reachingThresholdTransitionsToFinalTen() {
        let state = makeState(totalTickets: 10, threshold: 8)
        for _ in 0..<8 {
            state.drawNextTicket()
            state.clearReveal()
        }

        #expect(state.phase == .finalTen)
        #expect(state.finalTenContestants.count == 2)
        #expect(state.drawHistory.count == 8)
    }

    // MARK: - Not Present / carryover

    @Test func notPresentCarriesOverSpecialPrizeToNextDraw() {
        let state = makeState()
        state.config.specialPrizes = ["1": 100.0]
        state.drawNextTicket()

        state.markNotPresent()

        #expect(state.carryoverPrize == 100.0)
        #expect(state.currentReveal == nil)
        let notPresentTicket = state.tickets.first { $0.id == state.drawHistory[0] }
        #expect(notPresentTicket?.wasNotPresent == true)
        #expect(notPresentTicket?.isSpecialPrize == false)

        state.drawNextTicket()

        let nextTicket = state.tickets.first { $0.id == state.currentReveal }
        #expect(nextTicket?.isSpecialPrize == true)
        #expect(nextTicket?.prizeAmount == 100.0)
        #expect(state.carryoverPrize == nil)
        // overall draw count continues sequentially, not-present draw still counted
        #expect(state.drawHistory.count == 2)
    }

    // MARK: - Final Ten / Split Pot

    @Test func eliminationStopsAtOneRemaining() {
        let state = makeState(totalTickets: 10, threshold: 8)
        for _ in 0..<8 {
            state.drawNextTicket()
            state.clearReveal()
        }
        #expect(state.finalTenContestants.count == 2)

        state.drawElimination()
        state.clearReveal()
        #expect(state.finalTenContestants.count == 1)
        #expect(state.eliminated.count == 1)

        state.drawElimination() // no-op: can't eliminate the last remaining contestant
        #expect(state.finalTenContestants.count == 1)
    }

    @Test func splitPotFreezesRemainingAsWinnersAndDivisdesPotEvenly() {
        let state = makeState(totalTickets: 10, threshold: 7, finalTenPot: 90)
        for _ in 0..<7 {
            state.drawNextTicket()
            state.clearReveal()
        }
        #expect(state.finalTenContestants.count == 3)

        state.splitPot()

        #expect(state.potSplitDone == true)
        #expect(state.currentPotSplit == 30.0)
        #expect(state.finalTenContestants.count == 3) // unchanged by split itself

        state.drawElimination() // no-op once split is done
        #expect(state.finalTenContestants.count == 3)
    }

    @Test func startBonusDrawRequiresSplitDone() {
        let state = makeState(totalTickets: 10, threshold: 9)
        for _ in 0..<9 {
            state.drawNextTicket()
            state.clearReveal()
        }
        #expect(state.phase == .finalTen)

        state.startBonusDraw()
        #expect(state.phase == .finalTen) // refused: pot not split yet

        state.splitPot()
        state.startBonusDraw()

        #expect(state.phase == .bonusDraw)
        #expect(state.tickets.count == 10)
        #expect(state.tickets.allSatisfy { !$0.isDrawn })
    }

    @Test func drawBonusTicketCompletesEventAndWritesArchive() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let persistence = PersistenceManager(directoryOverride: tempDir)
        let state = EventState(persistence: persistence)
        state.eventName = "Archive Test"
        state.config.totalTickets = 10
        state.config.threshold = 9
        state.config.finalTenPot = 100
        state.config.bonusDrawAmount = 500
        state.startEvent()

        for _ in 0..<9 {
            state.drawNextTicket()
            state.clearReveal()
        }
        state.splitPot()
        state.startBonusDraw()
        state.drawBonusTicket()

        #expect(state.phase == .complete)
        #expect(state.currentReveal != nil)

        let eventsDir = tempDir.appendingPathComponent("Events")
        let files = try? FileManager.default.contentsOfDirectory(at: eventsDir, includingPropertiesForKeys: nil)
        #expect(files?.count == 1)
    }

    // MARK: - Undo / Reset

    @Test func undoRestoresPreviousState() {
        let state = makeState()
        state.drawNextTicket()
        #expect(state.canUndo == true)

        state.undo()

        #expect(state.drawHistory.isEmpty)
        #expect(state.currentReveal == nil)
    }

    @Test func resetReturnsToSetup() {
        let state = makeState()
        state.drawNextTicket()

        state.reset()

        #expect(state.phase == .setup)
        #expect(state.drawHistory.isEmpty)
        #expect(state.eventName.isEmpty)
    }
}
