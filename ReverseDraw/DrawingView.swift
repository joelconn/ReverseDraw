import SwiftUI

struct DrawingView: View {
    @Environment(EventState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            revealHeader
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.regularMaterial)

            Divider()

            drawnList

            Divider()

            toolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }

    private var revealHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Draw")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Group {
                    if let reveal = state.currentReveal {
                        Text("#\(reveal)")
                    } else {
                        Text("—").foregroundStyle(.tertiary)
                    }
                }
                .font(.system(size: 48, weight: .bold, design: .rounded))

                if let reveal = state.currentReveal,
                   let ticket = state.tickets.first(where: { $0.id == reveal }),
                   ticket.isSpecialPrize {
                    Label("Special Prize – \(ticket.prizeAmount.formatted(.currency(code: "USD")))", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(.yellow)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(state.config.totalTickets - state.drawHistory.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(remainingColor)
            }
        }
    }

    private var drawnList: some View {
        List {
            ForEach(state.drawHistory.indices.reversed(), id: \.self) { i in
                let ticketID = state.drawHistory[i]
                let drawNum = i + 1
                let isLatest = ticketID == state.currentReveal
                let ticket = state.tickets.first(where: { $0.id == ticketID })
                let isSpecial = ticket?.isSpecialPrize ?? false
                let prizeAmount = ticket?.prizeAmount ?? 0

                HStack(spacing: 12) {
                    Text("Draw \(drawNum)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 64, alignment: .leading)

                    Text("#\(ticketID)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(isLatest ? .bold : .regular)

                    if isSpecial {
                        Label(prizeAmount.formatted(.currency(code: "USD")), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    Spacer()

                    if isLatest {
                        Text("Latest")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
                .listRowBackground(isLatest ? Color.blue.opacity(0.05) : Color.clear)
            }
        }
        .listStyle(.plain)
    }

    private var toolbar: some View {
        HStack {
            Button("Undo") { state.undo() }
                .disabled(state.undoStack.isEmpty)
                .keyboardShortcut("z", modifiers: .command)

            Spacer()

            Text("\(state.drawHistory.count) of \(state.config.totalTickets) drawn")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Draw Next Ticket") { state.drawNextTicket() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.space, modifiers: [])
        }
    }

    private var remainingColor: Color {
        let remaining = state.config.totalTickets - state.drawHistory.count
        let finalTenCount = state.config.totalTickets - state.config.threshold
        if remaining <= finalTenCount { return .red }
        if remaining <= finalTenCount * 3 { return .orange }
        return .primary
    }
}
