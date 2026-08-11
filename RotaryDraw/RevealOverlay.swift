import SwiftUI

struct RevealOverlay: View {
    @Environment(EventState.self) private var state
    @State private var scale: CGFloat = 0.05
    @State private var opacity: Double = 0
    @State private var showConfetti = false

    var body: some View {
        if let ticket = state.revealTicket {
            let guest = state.guest(for: ticket.id)
            let isGrandWinner = state.phase == .complete
            let isElimination = state.currentRevealIsElimination
            let isCelebration = ticket.isSpecialPrize || isGrandWinner

            ZStack {
                Color.black.opacity(0.93)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text(isGrandWinner ? "WINNER" : (isElimination ? "ELIMINATED" : (ticket.isSpecialPrize ? "SPECIAL PRIZE" : "TICKET NUMBER")))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(isCelebration ? Color.yellow : (isElimination ? Color.red : Color.secondary))
                        .tracking(4)

                    Text("#\(ticket.id)")
                        .font(.system(size: 200, weight: .black, design: .rounded))
                        .foregroundStyle(isCelebration ? Color.yellow : (isElimination ? Color.red.opacity(0.85) : .white))
                        .shadow(color: isCelebration ? Color.yellow.opacity(0.4) : .clear, radius: 40)
                        .strikethrough(isElimination, color: .red.opacity(0.6))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)

                    if isGrandWinner && state.config.bonusDrawAmount > 0 {
                        Text(state.config.bonusDrawAmount, format: .currency(code: "USD"))
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    } else if ticket.isSpecialPrize && ticket.prizeAmount > 0 {
                        Text(ticket.prizeAmount, format: .currency(code: "USD"))
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    } else if isElimination && state.config.finalTenPot > 0 {
                        VStack(spacing: 4) {
                            Text(state.currentPotSplit, format: .currency(code: "USD"))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(.teal)
                            Text("each — \(state.finalTenContestants.count) remaining of \(state.config.finalTenPot, format: .currency(code: "USD")) pot")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let guest {
                        GuestNameplate(guest: guest)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer()

                    if let drawPosition = ticket.drawOrder {
                        Text("Draw \(drawPosition)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 40)
                .scaleEffect(scale)
                .opacity(opacity)

                if showConfetti {
                    ConfettiView(intensity: .dramatic)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()
            .transition(.opacity)
            .id(ticket.id)
            .onAppear { handleAppear(ticket: ticket, isCelebration: isCelebration) }
        }
    }

    private func handleAppear(ticket: Ticket, isCelebration: Bool) {
        scale = 0.05
        opacity = 0
        showConfetti = false

        withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) {
            scale = 1.0
            opacity = 1.0
        }

        let duration = isCelebration
            ? state.config.winnerRevealDuration
            : state.config.normalRevealDuration

        if isCelebration {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.4)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                state.clearReveal()
            }
        }
    }
}

// MARK: - Guest name display used across winning screens

struct GuestNameplate: View {
    let guest: GuestInfo

    var body: some View {
        VStack(spacing: 6) {
            Text(guest.name)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if let level = guest.sponsorLevel {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text(level)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.yellow)
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
    }
}
