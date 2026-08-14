import SwiftUI

struct OperatorView: View {
    @Environment(EventState.self) private var state
    @Environment(WindowManager.self) private var windowManager
    @State private var showSettings = false
    @State private var showInfo = false

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

            #if os(macOS)
            if windowManager.audienceWindow == nil {
                Button(action: { windowManager.openAudienceWindow(eventState: state) }) {
                    Image(systemName: "rectangle.righthalf.inset.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Reopen Audience Window")
            }
            #endif

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
                HStack(spacing: 8) {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                        Text("Settings")
                        Spacer()
                        Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.primary)
                    .buttonStyle(.bordered)

                    Button(action: { showInfo.toggle() }) {
                        Image(systemName: "info.circle")
                    }
                    .font(.subheadline.bold())
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundStyle(.primary)
                    .buttonStyle(.bordered)
                }

                if showSettings {
                    settingsPanel
                }

                if showInfo {
                    eventInfoPanel
                }

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

                Button("Exit & Save", systemImage: "arrow.uturn.left") {
                    state.reset()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var eventInfoPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Event Info")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Event Name")
                        .font(.caption)
                    Spacer()
                    Text(state.eventName)
                        .font(.caption.bold())
                }

                Divider()

                HStack {
                    Text("Total Tickets")
                        .font(.caption)
                    Spacer()
                    Text("\(state.config.totalTickets)")
                        .font(.caption.bold())
                }

                HStack {
                    Text("Unused Tickets")
                        .font(.caption)
                    Spacer()
                    Text("\(state.config.unusedTickets.count)")
                        .font(.caption.bold())
                }

                HStack {
                    Text("Guest List")
                        .font(.caption)
                    Spacer()
                    Text("\(state.guestList.count) guests")
                        .font(.caption.bold())
                }

                Divider()

                HStack {
                    Text("Price Per Ticket")
                        .font(.caption)
                    Spacer()
                    Text(state.config.pricePerTicket, format: .currency(code: "USD"))
                        .font(.caption.bold())
                }

                HStack {
                    Text("Total Revenue")
                        .font(.caption)
                    Spacer()
                    Text(state.config.totalRevenue, format: .currency(code: "USD"))
                        .font(.caption.bold())
                }

                HStack {
                    Text("Prize Pool (50%)")
                        .font(.caption)
                    Spacer()
                    Text(state.config.totalPrizePool, format: .currency(code: "USD"))
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }

                Divider()

                HStack {
                    Text("Special Prizes")
                        .font(.caption)
                    Spacer()
                    Text(state.config.specialPrizesTotal, format: .currency(code: "USD"))
                        .font(.caption.bold())
                }

                HStack {
                    Text("Final Ten Threshold")
                        .font(.caption)
                    Spacer()
                    Text("After draw #\(state.config.threshold)")
                        .font(.caption.bold())
                }

                HStack {
                    Text("Final Ten Pot")
                        .font(.caption)
                    Spacer()
                    Text(state.config.finalTenPot, format: .currency(code: "USD"))
                        .font(.caption.bold())
                }

                HStack {
                    Text("Bonus Draw Amount")
                        .font(.caption)
                    Spacer()
                    Text(state.config.bonusDrawAmount, format: .currency(code: "USD"))
                        .font(.caption.bold())
                }
            }
            .padding(10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private var settingsPanel: some View {
        VStack(spacing: 12) {
            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Event Configuration")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Total Tickets")
                        .font(.caption)
                    Spacer()
                    TextField("250", value: Binding(
                        get: { state.config.numTickets },
                        set: { state.config.numTickets = $0 }
                    ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }

                HStack {
                    Text("Final Ten After Draw #")
                        .font(.caption)
                    Spacer()
                    TextField("240", value: Binding(
                        get: { state.config.threshold },
                        set: { state.config.threshold = $0 }
                    ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
            .padding(10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 10) {
                Text("Reveal Durations (seconds)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Normal")
                        .font(.caption)
                    Spacer()
                    TextField("5", value: Binding(
                        get: { state.config.normalRevealDuration },
                        set: { state.config.normalRevealDuration = $0 }
                    ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }

                HStack {
                    Text("Winner")
                        .font(.caption)
                    Spacer()
                    TextField("12", value: Binding(
                        get: { state.config.winnerRevealDuration },
                        set: { state.config.winnerRevealDuration = $0 }
                    ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }
            .padding(10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 10) {
                Text("Prize Amounts")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Bonus Draw")
                        .font(.caption)
                    Spacer()
                    TextField("$0", value: Binding(
                        get: { state.config.bonusDrawAmount },
                        set: { state.config.bonusDrawAmount = $0 }
                    ), format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }
            }
            .padding(10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                Text("Special Draw Amounts")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if state.config.specialPrizes.isEmpty {
                    Text("No special prizes configured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    let sortedPrizes = state.config.specialPrizes
                        .sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }

                    ForEach(sortedPrizes, id: \.key) { key, amount in
                        HStack {
                            Text("Draw #\(key)")
                                .font(.caption)
                            Spacer()
                            TextField("$0", value: Binding(
                                get: { amount },
                                set: { state.config.specialPrizes[key] = $0 }
                            ), format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                        }
                    }
                }
            }
            .padding(10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Drawing Controls

    private var drawSection: some View {
        VStack(spacing: 12) {
            Button {
                state.drawNextTicket()
            } label: {
                Label("Draw Next Ticket", systemImage: "ticket.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.space, modifiers: [])
            .disabled(state.currentReveal != nil)

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
            .disabled(state.lastRevealedTicketID == nil)

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
                    Label("Draw Elimination", systemImage: "ticket.fill")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .disabled(state.finalTenContestants.count <= 1 || state.currentReveal != nil)
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
            }

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

            if !state.potSplitDone {
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
                    let guest = state.guest(for: ticketID)
                    let isSpecial = ticket?.isSpecialPrize ?? false
                    let isNotPresent = ticket?.wasNotPresent ?? false

                    HStack(spacing: 10) {
                        Text("Draw \(drawNum)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 62, alignment: .leading)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("#\(ticketID)")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(isLatest ? .bold : (isSpecial ? .semibold : .regular))
                                .foregroundStyle(
                                    isNotPresent ? Color.secondary :
                                    isSpecial ? Color(red: 0.85, green: 0.65, blue: 0.0) : .primary
                                )
                                .strikethrough(isNotPresent, color: .secondary)
                            if let guestName = guest?.name {
                                Text(guestName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

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
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
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
