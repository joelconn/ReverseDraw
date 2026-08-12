import SwiftUI

// MARK: - Audience Window (TV display)

struct AudienceView: View {
    @Environment(EventState.self) private var state

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            switch state.phase {
            case .setup:
                holdingScreen
            case .drawing:
                AudienceDrawingView()
            case .finalTen:
                FinalTenView()
            case .bonusDraw, .complete:
                AudienceWinnerView()
            }

            RevealOverlay()
        }
        .preferredColorScheme(.dark)
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 600)
        #endif
    }

    private var holdingScreen: some View {
        VStack(spacing: 20) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue)
            Text("Rotary Reverse Drawing")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Event starting soon")
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Drawing phase: grid + ticker

struct AudienceDrawingView: View {
    @Environment(EventState.self) private var state

    private let spacing: CGFloat = 3

    private func bestGrid(count: Int, aspect: CGFloat) -> (cols: Int, rows: Int) {
        guard count > 0 else { return (1, 1) }
        var best = (cols: count, rows: 1)
        var bestDiff = CGFloat.greatestFiniteMagnitude
        for cols in 1...count {
            let rows = Int(ceil(Double(count) / Double(cols)))
            let gridAspect = CGFloat(cols) / CGFloat(rows)
            let diff = abs(gridAspect - aspect)
            if diff < bestDiff {
                bestDiff = diff
                best = (cols, rows)
            }
        }
        return best
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let aspect = geo.size.width / max(geo.size.height, 1)
                let grid = bestGrid(count: state.tickets.count, aspect: aspect)
                let cols = grid.cols
                let rows = grid.rows
                let cellW = (geo.size.width - CGFloat(cols - 1) * spacing) / CGFloat(cols)
                let cellH = (geo.size.height - CGFloat(rows - 1) * spacing) / CGFloat(rows)

                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<cols, id: \.self) { col in
                                let index = row * cols + col
                                if index < state.tickets.count {
                                    let ticket = state.tickets[index]
                                    TicketCell(
                                        ticket: ticket,
                                        isCurrentReveal: ticket.id == state.currentReveal,
                                        fontSize: min(cellW, cellH) * 0.28
                                    )
                                    .frame(width: cellW, height: cellH)
                                }
                            }
                        }
                    }
                }
            }

            drawnTicker
                .frame(height: 58)
                .background(Color.white.opacity(0.05))
        }
    }

    private var drawnTicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("Draw order:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.leading, 10)

                    ForEach(state.drawHistory.indices, id: \.self) { i in
                        let ticketID = state.drawHistory[i]
                        let drawNum = i + 1
                        let isLatest = ticketID == state.currentReveal
                        let ticket = state.tickets.first(where: { $0.id == ticketID })
                        let isSpecial = ticket?.isSpecialPrize ?? false
                        let isNotPresent = ticket?.wasNotPresent ?? false

                        VStack(spacing: 1) {
                            Text("#\(ticketID)")
                                .font(.system(size: isLatest ? 16 : 12, weight: isLatest ? .bold : .regular, design: .monospaced))
                                .foregroundStyle(
                                    isLatest ? Color.black :
                                    isNotPresent ? Color.white.opacity(0.25) :
                                    isSpecial ? Color.yellow : Color.white
                                )
                                .strikethrough(isNotPresent, color: Color.white.opacity(0.3))
                            Text("\(drawNum)")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(isLatest ? Color.black.opacity(0.5) : Color.white.opacity(0.35))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    isLatest ? Color.yellow :
                                    isNotPresent ? Color.red.opacity(0.15) :
                                    isSpecial ? Color.yellow.opacity(0.18) : Color.white.opacity(0.07)
                                )
                        )
                        .id(ticketID)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .onChange(of: state.drawHistory.count) { _, _ in
                if let last = state.drawHistory.last {
                    withAnimation { proxy.scrollTo(last, anchor: .trailing) }
                }
            }
        }
    }
}

// MARK: - Winner / Bonus Draw audience display

struct AudienceWinnerView: View {
    @Environment(EventState.self) private var state
    @State private var pulse = false

    var body: some View {
        ZStack {
            ConfettiView(intensity: .normal, loop: true)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            winnerContent
        }
    }

    private var winnerContent: some View {
        VStack(spacing: 28) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 100))
                .foregroundStyle(.yellow)
                .shadow(color: Color.yellow.opacity(0.5), radius: 30)
                .scaleEffect(pulse ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)

            Text("Winner!")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            if let winner = state.currentReveal {
                Text("Ticket #\(winner)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 20))
            }

            if state.config.bonusDrawAmount > 0 {
                Text(state.config.bonusDrawAmount, format: .currency(code: "USD"))
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.green)
            }

            if let winner = state.currentReveal, let guest = state.guest(for: winner) {
                GuestNameplate(guest: guest)
                    .padding(.top, 8)
            }
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Ticket Cell (used by audience grid)

struct TicketCell: View {
    let ticket: Ticket
    let isCurrentReveal: Bool
    var fontSize: CGFloat = 10

    var isFinalTenContestant: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(background)
            .overlay(
                Text("\(ticket.id)")
                    .font(.system(size: fontSize, weight: isCurrentReveal ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(foreground)
                    .minimumScaleFactor(0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(border, lineWidth: isCurrentReveal ? 2 : 0.5)
            )
            .animation(.easeOut(duration: 0.4), value: ticket.isDrawn)
    }

    private var background: Color {
        if ticket.isUnused { return Color.white.opacity(0.02) }
        if isCurrentReveal { return .yellow }
        if ticket.isSpecialPrize && !ticket.isDrawn { return Color(red: 0.3, green: 0.22, blue: 0.0) }
        if ticket.isDrawn { return Color.white.opacity(0.04) }
        return Color.white.opacity(0.10)
    }

    private var foreground: Color {
        if ticket.isUnused { return Color.white.opacity(0.1) }
        if isCurrentReveal { return .black }
        if ticket.isDrawn { return Color.white.opacity(0.2) }
        if ticket.isSpecialPrize { return Color.yellow.opacity(0.9) }
        return .white
    }

    private var border: Color {
        if ticket.isUnused { return Color.white.opacity(0.04) }
        if isCurrentReveal { return .orange }
        if ticket.isSpecialPrize && !ticket.isDrawn { return Color.yellow.opacity(0.5) }
        if ticket.isDrawn { return Color.white.opacity(0.08) }
        return Color.white.opacity(0.18)
    }
}

// MARK: - Flow Layout (used elsewhere)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
