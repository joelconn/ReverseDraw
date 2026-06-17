import SwiftUI

struct OperatorView: View {
    @Environment(EventState.self) private var state

    var drawCount: Int { state.drawHistory.count }
    var threshold: Int { state.config.threshold }
    var remaining: Int { state.config.totalTickets - drawCount }

    var body: some View {
        VStack(spacing: 0) {
            phaseHeader
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.regularMaterial)

            Divider()

            HStack(spacing: 0) {
                controlColumn
                    .frame(width: 300)
                    .background(.background)

                Divider()

                historyColumn
            }

            Divider()

            autoSaveBar
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(.regularMaterial)
        }
        #if os(macOS)
        .frame(minWidth: 640, minHeight: 520)
        #endif
    }

    // MARK: - Phase Header

    private var phaseHeader: some View {
        HStack {
            phaseBadge

            Spacer()

            if state.phase == .drawing {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Draw \(drawCount) of \(threshold)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("\(remaining) tickets remaining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if state.phase == .finalTen {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(state.finalTenContestants.count) remaining")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.teal)
                    Text("of \(state.config.totalTickets - threshold) final contestants")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var phaseBadge: some View {
        Text(state.phase.displayName.uppercased())
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(state.phase.badgeColor, in: Capsule())
    }

    // MARK: - Control Column (left)

    private var controlColumn: some View {
        ScrollView {
            VStack(spacing: 16) {
                if state.phase == .drawing {
                    drawSection
                }

                if state.phase == .finalTen {
                    finalTenSection
                }

                if state.phase == .bonusDraw {
                    bonusSection
                }

                if state.phase == .complete {
                    completeSection
                }

                Spacer(minLength: 20)
            }
            .padding(16)
        }
    }

    // MARK: - Drawing Controls

    private var drawSection: some View {
        VStack(spacing: 12) {
            Button {
                state.drawNextTicket()
            } label: {
                Label(
                    state.currentReveal != nil ? "Drawing..." : "Draw Next Ticket",
                    systemImage: "ticket.fill"
                )
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(state.currentReveal != nil)
            .keyboardShortcut(.space, modifiers: [])

            Button {
                state.markNotPresent()
            } label: {
                Label("Not Present", systemImage: "person.slash.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .disabled(state.currentReveal == nil)

            if let carryover = state.carryoverPrize {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Prize carries over: \(carryover, format: .currency(code: "USD"))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }

            Button {
                state.undo()
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Undo")
                    if state.undoStack.count > 0 {
                        Text("(\(state.undoStack.count))")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!state.canUndo)
            .keyboardShortcut("z", modifiers: .command)
        }
    }

    // MARK: - Final Ten Controls

    private var finalTenSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if state.config.finalTenPot > 0 {
                VStack(spacing: 4) {
                    Text(state.currentPotSplit, format: .currency(code: "USD"))
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(state.potSplitDone ? .yellow : .teal)
                        .contentTransition(.numericText())

                    Text("each — \(state.finalTenContestants.count) \(state.potSplitDone ? "winner\(state.finalTenContestants.count == 1 ? "" : "s")" : "contestants")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("of \(state.config.finalTenPot, format: .currency(code: "USD")) pot")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background((state.potSplitDone ? Color.yellow : Color.teal).opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                Divider()
            }

            if !state.potSplitDone {
                Button {
                    state.drawElimination()
                } label: {
                    Label(
                        state.currentReveal != nil ? "Drawing..." : "Draw Elimination",
                        systemImage: "ticket.fill"
                    )
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .disabled(state.currentReveal != nil || state.finalTenContestants.count <= 1)
                .keyboardShortcut(.space, modifiers: [])

                Button {
                    state.splitPot()
                } label: {
                    Label("Split Pot", systemImage: "dollarsign.circle.fill")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .controlSize(.large)
                .disabled(state.currentReveal != nil || state.finalTenContestants.isEmpty)

                Divider()
            }

            Text(state.potSplitDone ? "Winners" : "Active Contestants")
                .font(.headline)

            if state.finalTenContestants.isEmpty {
                Text("No contestants remaining")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(state.finalTenContestants, id: \.self) { id in
                    OperatorContestantRow(
                        ticketID: id,
                        isEliminated: false,
                        winAmount: state.potSplitDone ? state.currentPotSplit : nil
                    )
                }
            }

            if !state.eliminated.isEmpty {
                Divider()
                Text("Eliminated")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ForEach(state.eliminated.reversed(), id: \.self) { id in
                    OperatorContestantRow(ticketID: id, isEliminated: true)
                }
            }

            Divider()

            Button("Start Bonus Draw") {
                state.startBonusDraw()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .frame(maxWidth: .infinity)
            .disabled(!state.potSplitDone)

            Button { state.undo() } label: {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Undo")
                    if state.undoStack.count > 0 {
                        Text("(\(state.undoStack.count))").foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!state.canUndo)
            .keyboardShortcut("z", modifiers: .command)
        }
    }

    // MARK: - Bonus Draw Controls

    private var bonusSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Bonus Draw")
                .font(.title2.bold())

            Text("All tickets reset. Draw the final winner.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Button("Draw Bonus Ticket") {
                state.drawBonusTicket()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Complete Section

    private var completeSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)

            Text("Event Complete")
                .font(.title2.bold())

            if let winner = state.currentReveal {
                Text("Winner: Ticket #\(winner)")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }

            if state.config.bonusDrawAmount > 0 {
                Text(state.config.bonusDrawAmount, format: .currency(code: "USD"))
                    .font(.title2.bold())
                    .foregroundStyle(.green)
            }

            Button("Start New Event") { state.reset() }
                .buttonStyle(.bordered)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - History Column (right)

    private var historyColumn: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Draw History")
                    .font(.headline)
                Spacer()
                Text("\(drawCount) drawn")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)

            Divider()

            List {
                ForEach(state.drawHistory.indices.reversed(), id: \.self) { i in
                    let ticketID = state.drawHistory[i]
                    let drawNum = i + 1
                    let isLatest = ticketID == state.currentReveal
                    let ticket = state.tickets.first { $0.id == ticketID }
                    let isSpecial = ticket?.isSpecialPrize ?? false
                    let isNotPresent = ticket?.wasNotPresent ?? false

                    HStack(spacing: 10) {
                        Text("Draw \(drawNum)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 62, alignment: .leading)

                        Text("#\(ticketID)")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(isLatest ? .bold : (isSpecial ? .semibold : .regular))
                            .foregroundStyle(
                                isNotPresent ? Color.secondary :
                                isSpecial ? Color(red: 0.85, green: 0.65, blue: 0.0) : .primary
                            )
                            .strikethrough(isNotPresent, color: .secondary)

                        if isSpecial {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            if let amt = ticket?.prizeAmount, amt > 0 {
                                Text(amt, format: .currency(code: "USD"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if isNotPresent {
                            Text("N/P")
                                .font(.caption2.bold())
                                .foregroundStyle(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red.opacity(0.1), in: Capsule())
                        } else if isLatest {
                            Text("Latest")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.1), in: Capsule())
                        }
                    }
                    .listRowBackground(
                        isNotPresent ? Color.red.opacity(0.04) :
                        isSpecial ? Color.yellow.opacity(0.07) :
                        isLatest ? Color.blue.opacity(0.05) : Color.clear
                    )
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Auto-Save Bar

    private var autoSaveBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.green)
                .frame(width: 7, height: 7)
            Text("Saved \(state.lastSavedAt.formatted(date: .omitted, time: .standard))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Contestant Row (operator)

struct OperatorContestantRow: View {
    let ticketID: Int
    let isEliminated: Bool
    var winAmount: Double? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isEliminated ? "xmark.circle.fill" : (winAmount != nil ? "star.fill" : "checkmark.circle.fill"))
                .foregroundStyle(isEliminated ? .red : (winAmount != nil ? .yellow : .teal))

            Text("Ticket #\(ticketID)")
                .font(.body)
                .fontWeight(isEliminated ? .regular : .semibold)
                .strikethrough(isEliminated, color: .secondary)
                .foregroundStyle(isEliminated ? .secondary : .primary)

            Spacer()

            if let winAmount {
                Text(winAmount, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isEliminated ? Color.red.opacity(0.06) : (winAmount != nil ? Color.yellow.opacity(0.12) : Color.teal.opacity(0.08)))
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 1, anchor: .top).combined(with: .opacity),
            removal: .scale(scale: 0.9, anchor: .top).combined(with: .opacity)
        ))
    }
}

// MARK: - EventPhase display helpers

private extension EventPhase {
    var displayName: String {
        switch self {
        case .setup: return "Setup"
        case .drawing: return "Drawing"
        case .finalTen: return "Final Ten"
        case .bonusDraw: return "Bonus Draw"
        case .complete: return "Complete"
        }
    }

    var badgeColor: Color {
        switch self {
        case .setup: return .gray
        case .drawing: return .blue
        case .finalTen: return .teal
        case .bonusDraw: return .orange
        case .complete: return .green
        }
    }
}
