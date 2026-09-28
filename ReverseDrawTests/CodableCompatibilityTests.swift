import Testing
import Foundation
@testable import ReverseDraw

/// Saved sessions and event archives from earlier app versions must keep
/// decoding as fields get added. These pin that contract against the exact
/// older JSON shapes (missing bonusDrawAmount, potSplitDone, eventName, etc.)
/// so a future field addition that breaks it fails here, not at a live event.
@MainActor
struct CodableCompatibilityTests {

    @Test func eventConfigDecodesJSONMissingBonusDrawAmount() throws {
        let oldJSON = """
        {
            "totalTickets": 250,
            "normalRevealDuration": 5,
            "winnerRevealDuration": 12,
            "finalTenPot": 1000,
            "threshold": 240,
            "specialPrizes": {}
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(EventConfig.self, from: oldJSON)

        #expect(config.totalTickets == 250)
        #expect(config.finalTenPot == 1000)
        #expect(config.bonusDrawAmount == 0.0)
    }

    @Test func eventConfigDecodesEmptyObject() throws {
        let emptyJSON = "{}".data(using: .utf8)!
        let config = try JSONDecoder().decode(EventConfig.self, from: emptyJSON)

        #expect(config.totalTickets == 250)
        #expect(config.threshold == 240)
        #expect(config.bonusDrawAmount == 0.0)
    }

    @Test func snapshotDecodesJSONMissingNewerFields() throws {
        let oldJSON = """
        {
            "tickets": [],
            "drawHistory": [],
            "currentReveal": null,
            "phase": "setup",
            "finalTenContestants": [],
            "eliminated": [],
            "config": {},
            "timestamp": 0
        }
        """.data(using: .utf8)!

        let snapshot = try JSONDecoder().decode(Snapshot.self, from: oldJSON)

        #expect(snapshot.phase == .setup)
        #expect(snapshot.carryoverPrize == nil)
        #expect(snapshot.potSplitDone == nil)
        #expect(snapshot.eventName == nil)
    }

    @Test func snapshotRoundTripsThroughEncodeDecode() throws {
        let original = Snapshot(
            tickets: [Ticket(id: 1), Ticket(id: 2)],
            drawHistory: [1],
            currentReveal: 1,
            phase: .drawing,
            finalTenContestants: [],
            eliminated: [],
            config: EventConfig(),
            timestamp: Date(),
            carryoverPrize: 50.0,
            potSplitDone: true,
            eventName: "Round Trip Event"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Snapshot.self, from: data)

        #expect(decoded.drawHistory == [1])
        #expect(decoded.currentReveal == 1)
        #expect(decoded.carryoverPrize == 50.0)
        #expect(decoded.potSplitDone == true)
        #expect(decoded.eventName == "Round Trip Event")
    }
}
