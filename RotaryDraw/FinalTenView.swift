import SwiftUI

// Audience-side Final Ten display (shown in AudienceView when phase == .finalTen)
struct FinalTenView: View {
    @Environment(EventState.self) private var state

    @State private var potSplitScale: CGFloat = 1.0

    var potSplit: Double { state.currentPotSplit }
    var remaining: Int { state.finalTenContestants.count }
    var pot: Double { state.config.finalTenPot }

    var body: some View {
        ZStack {
            if state.potSplitDone {
                ConfettiView(intensity: .dramatic, loop: true)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 40) {
                VStack(spacing: 10) {
                    Text(state.potSplitDone ? "Final 10 Winners!" : "Final 10")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(state.potSplitDone ? .yellow : .teal)

                    if pot > 0 {
                        Text(potSplit, format: .currency(code: "USD"))
                            .font(.system(size: 96, weight: .black, design: .rounded))
                            .foregroundStyle(.yellow)
                            .scaleEffect(potSplitScale)
                            .contentTransition(.numericText())
                            .onChange(of: potSplit) { _, _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                    potSplitScale = 1.15
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        potSplitScale = 1.0
                                    }
                                }
                            }

                        Text(state.potSplitDone
                             ? "each — \(remaining) winner\(remaining == 1 ? "" : "s") split \(pot, format: .currency(code: "USD")) pot"
                             : "\(remaining) contestant\(remaining == 1 ? "" : "s") remaining — \(pot, format: .currency(code: "USD")) pot")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }

                contestantGrid
            }
            .padding(40)
        }
    }

    private var contestantGrid: some View {
        let allIDs = (state.finalTenContestants + state.eliminated).sorted()

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5),
            spacing: 16
        ) {
            ForEach(allIDs, id: \.self) { id in
                let isEliminated = state.eliminated.contains(id)
                let isWinner = state.potSplitDone && !isEliminated
                FinalTenCard(
                    ticketID: id,
                    isEliminated: isEliminated,
                    isWinner: isWinner,
                    winAmount: isWinner ? state.currentPotSplit : nil
                )
            }
        }
        .padding(.horizontal, 40)
    }
}

struct FinalTenCard: View {
    @Environment(EventState.self) private var state

    let ticketID: Int
    let isEliminated: Bool
    var isWinner: Bool = false
    var winAmount: Double? = nil

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 4) {
            Text("#\(ticketID)")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(isEliminated ? Color.secondary.opacity(0.4) : (isWinner ? Color.black : .white))
                .strikethrough(isEliminated, color: .secondary)

            if let guest = state.guest(for: ticketID) {
                Text(guest.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(isEliminated ? Color.secondary.opacity(0.4) : (isWinner ? Color.black.opacity(0.7) : .white))
                    .lineLimit(1)
            }

            if isWinner, let winAmount {
                Text(winAmount, format: .currency(code: "USD"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.7))
            }
        }
        .frame(width: 140, height: isWinner ? 128 : 116)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isEliminated ? Color.secondary.opacity(0.08) : (isWinner ? Color.yellow : Color.teal.opacity(0.2)))
                .scaleEffect(pulse ? 1.04 : 1.0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isEliminated ? Color.secondary.opacity(0.2) : (isWinner ? Color.yellow : Color.teal.opacity(0.6)),
                    lineWidth: isEliminated ? 1 : 2
                )
        )
        .opacity(isEliminated ? 0.45 : 1.0)
        .animation(.easeOut(duration: 0.4), value: isEliminated)
        .onAppear {
            if !isEliminated && !isWinner {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(Double(ticketID % 5) * 0.2)) {
                    pulse = true
                }
            }
        }
        .onChange(of: isEliminated) { _, eliminated in
            if eliminated { pulse = false }
        }
    }
}
