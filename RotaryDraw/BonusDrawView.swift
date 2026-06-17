import SwiftUI

struct BonusDrawView: View {
    @Environment(EventState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if state.phase == .complete {
                winnerView
            } else {
                readyView
            }

            Spacer()
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 420)
        #endif
    }

    private var readyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text("Bonus Draw")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("All tickets have been reset.\nDraw one final winning ticket.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.title3)

            Button("Draw Winning Ticket") { state.drawBonusTicket() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 8)
        }
    }

    private var winnerView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 88))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.4), radius: 20)

            Text("Winner!")
                .font(.system(size: 64, weight: .bold, design: .rounded))

            if let winner = state.currentReveal {
                Text("Ticket #\(winner)")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }

            if state.config.bonusDrawAmount > 0 {
                Text(state.config.bonusDrawAmount, format: .currency(code: "USD"))
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.green)
            }

            Button("Start New Event") { state.reset() }
                .buttonStyle(.bordered)
                .padding(.top, 20)
        }
    }
}
