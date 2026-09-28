import SwiftUI
import UniformTypeIdentifiers

struct SetupView: View {
    @Environment(EventState.self) private var state

    @State private var newDrawNumber: String = ""
    @State private var newPrizeAmount: String = ""
    @State private var showAddRow = false
    @State private var guestLoadResult: String? = nil
    @State private var showFilePicker = false
    @State private var templateName: String = ""
    @State private var savedSetups: [String] = []
    @State private var recoveryTickets: String = ""
    @State private var unusedTickets: String = ""
    @State private var showUpdates = false
    @State private var totalPrizePoolInput: Double = 0

    var sortedSpecialPrizes: [(key: String, value: Double)] {
        state.config.specialPrizes
            .sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
    }

    var body: some View {
        @Bindable var state = state

        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Reverse Drawing")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Event Setup")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                if PersistenceManager.shared.hasSession {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.orange)
                        Text("Previous session found")
                            .font(.subheadline)
                        Spacer()
                        Button("Resume") { state.loadSession() }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .controlSize(.small)
                    }
                    .padding(12)
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: 440)
                }

                VStack(alignment: .leading, spacing: 24) {
                    SettingsSection(title: "Event Name") {
                        TextField("e.g. Spring Gala 2026", text: $state.eventName)
                            .textFieldStyle(.roundedBorder)
                    }

                    SettingsSection(title: "Unused Tickets (Optional)") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Comma or space separated ticket numbers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $unusedTickets)
                                .font(.system(.body, design: .monospaced))
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 60)
                            if !state.config.unusedTickets.isEmpty {
                                Text("Unused: \(state.config.unusedTickets.sorted().map(String.init).joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Button("Set Unused Tickets") {
                                updateUnusedTickets()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    SettingsSection(title: "Prize Money Calculator") {
                        SettingsRow(label: "Number of Tickets") {
                            TextField("250", value: $state.config.numTickets, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        SettingsRow(label: "Price Per Ticket") {
                            TextField("$0", value: $state.config.pricePerTicket, format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .onChange(of: state.config.pricePerTicket) {
                                    totalPrizePoolInput = state.config.totalPrizePool
                                }
                        }
                        Divider()
                        SettingsRow(label: "Total Revenue") {
                            Text(state.config.totalRevenue, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                                .frame(width: 120, alignment: .trailing)
                        }
                        SettingsRow(label: "Total Prize Pool") {
                            TextField("$0", value: $totalPrizePoolInput, format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .onChange(of: totalPrizePoolInput) {
                                    if totalPrizePoolInput > 0 {
                                        state.config.pricePerTicket = totalPrizePoolInput * 2.0 / Double(state.config.numTickets)
                                    }
                                }
                        }
                        SettingsRow(label: "Special Prizes") {
                            Text(state.config.specialPrizesTotal, format: .currency(code: "USD"))
                                .frame(width: 120, alignment: .trailing)
                        }
                        SettingsRow(label: "Remaining") {
                            Text(state.config.remainingPrizes, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                                .frame(width: 120, alignment: .trailing)
                        }
                    }
                    .onAppear {
                        totalPrizePoolInput = state.config.totalPrizePool
                    }

                    SettingsSection(title: "Event Settings") {
                        SettingsRow(label: "Final Ten After Draw #") {
                            Text("\(state.config.finalTenThreshold)")
                                .fontWeight(.semibold)
                                .frame(width: 120, alignment: .trailing)
                        }
                        Divider()
                        SettingsRow(label: "Bonus Draw Amount") {
                            TextField("$0", value: $state.config.bonusDrawAmount, format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                        }
                        SettingsRow(label: "Final Ten Pot") {
                            Text(state.config.finalTenPot, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                                .frame(width: 120, alignment: .trailing)
                        }
                    }

                    SettingsSection(title: "Reveal Durations (seconds)") {
                        SettingsRow(label: "Normal Reveal") {
                            TextField("5", value: $state.config.normalRevealDuration, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        SettingsRow(label: "Winner Reveal") {
                            TextField("12", value: $state.config.winnerRevealDuration, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }

                    SettingsSection(title: "Special Prize Draws") {
                        if !state.config.unreachableSpecialPrizes.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unreachable Prizes")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Draw(s) \(state.config.unreachableSpecialPrizes.joined(separator: ", ")) are beyond the final ten threshold (\(state.config.finalTenThreshold)). These won't apply—final ten starts at draw \(state.config.finalTenThreshold + 1).")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    for key in state.config.unreachableSpecialPrizes {
                                        state.config.specialPrizes.removeValue(forKey: key)
                                    }
                                } label: {
                                    Text("Remove")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(12)
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            .padding(.bottom, 8)
                        }

                        if !sortedSpecialPrizes.isEmpty {
                            HStack {
                                Text("Draw #")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60, alignment: .leading)
                                Text("Prize")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }

                        ForEach(sortedSpecialPrizes, id: \.key) { entry in
                            HStack {
                                Text("Draw #\(entry.key)")
                                    .frame(width: 70, alignment: .leading)
                                Spacer()
                                Text(entry.value, format: .currency(code: "USD"))
                                    .foregroundStyle(.secondary)
                                Button {
                                    state.config.specialPrizes.removeValue(forKey: entry.key)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }

                        if !sortedSpecialPrizes.isEmpty {
                            Divider()
                            HStack {
                                Text("Total")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(state.config.specialPrizesTotal, format: .currency(code: "USD"))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 4)
                        }

                        if showAddRow {
                            HStack(spacing: 8) {
                                TextField("Draw #", text: $newDrawNumber)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 90)
                                TextField("Prize $", text: $newPrizeAmount)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 110)
                                    .onSubmit { addSpecialPrize() }
                                Button("Add") {
                                    addSpecialPrize()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                Button("Cancel") {
                                    newDrawNumber = ""
                                    newPrizeAmount = ""
                                    showAddRow = false
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        HStack(spacing: 8) {
                            Button {
                                showAddRow = true
                            } label: {
                                Label("Add Prize Draw", systemImage: "plus.circle")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)

                            Spacer()

                            Button {
                                applySummerSizzleTemplate()
                            } label: {
                                Label("Summer Sizzle", systemImage: "star.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .foregroundStyle(.orange)
                        }
                    }

                    SettingsSection(title: "Setup Templates") {
                        HStack(spacing: 8) {
                            TextField("Template name", text: $templateName)
                                .textFieldStyle(.roundedBorder)
                            Button("Save") {
                                if !templateName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    PersistenceManager.shared.saveSetup(name: templateName, config: state.config)
                                    savedSetups = PersistenceManager.shared.listSetups()
                                    templateName = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }

                        if !savedSetups.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Saved Templates")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(savedSetups, id: \.self) { setup in
                                    HStack {
                                        Button(setup) {
                                            if let config = PersistenceManager.shared.loadSetup(name: setup) {
                                                state.config = config
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.blue)

                                        Spacer()

                                        Button {
                                            PersistenceManager.shared.deleteSetup(name: setup)
                                            savedSetups = PersistenceManager.shared.listSetups()
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    SettingsSection(title: "Guest List (optional)") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CSV format: Paddle #, First name, Last name [, Sponsor Level]")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let result = guestLoadResult {
                                    Text(result)
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else if !state.guestList.isEmpty {
                                    Text("\(state.guestList.count) guests loaded")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Load CSV") {
                                showFilePicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    SettingsSection(title: "Manual Recovery (Optional)") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Paste drawn ticket numbers (comma or space separated)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $recoveryTickets)
                                .font(.system(.body, design: .monospaced))
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 80)
                            Button("Recover from Tickets") {
                                state.recoverFromDrawnTickets(drawnIDs: parseRecoveryTickets())
                                recoveryTickets = ""
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .frame(maxWidth: 440)

                Button("Start Event") { state.startEvent() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .disabled(state.eventName.trimmingCharacters(in: .whitespaces).isEmpty)

                HStack(spacing: 12) {
                    Button("Updates") { showUpdates = true }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Spacer()

                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            savedSetups = PersistenceManager.shared.listSetups()
        }
        .sheet(isPresented: $showUpdates) {
            UpdatesView()
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 520)
        #endif
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let url = urls.first,
                  url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            if let text = try? String(contentsOf: url, encoding: .utf8) {
                let count = state.loadGuestCSV(text)
                guestLoadResult = "✓ \(count) guests loaded"
            } else {
                guestLoadResult = "⚠ Could not read file"
            }
        }
    }

    private func addSpecialPrize() {
        if let num = Int(newDrawNumber),
           num >= 1,
           num <= state.config.totalTickets,
           let amount = Double(
               newPrizeAmount
                   .replacingOccurrences(of: "$", with: "")
                   .replacingOccurrences(of: ",", with: "")
           ),
           amount > 0 {
            state.config.specialPrizes["\(num)"] = amount
            newDrawNumber = ""
            newPrizeAmount = ""
            showAddRow = false
        }
    }

    private func applySummerSizzleTemplate() {
        state.config.specialPrizes = [
            "1": 500,
            "20": 250,
            "40": 250,
            "60": 250,
            "80": 250,
            "100": 500,
            "120": 250,
            "140": 250,
            "160": 250,
            "180": 250,
            "200": 500,
            "220": 250,
            "240": 250
        ]
        state.config.bonusDrawAmount = 2000
    }

    private func parseRecoveryTickets() -> [Int] {
        recoveryTickets
            .split { !$0.isNumber && $0 != "-" }
            .compactMap { Int($0) }
    }

    private func updateUnusedTickets() {
        let parsed = Set(unusedTickets
            .split { !$0.isNumber && $0 != "-" }
            .compactMap { Int($0) }
            .filter { $0 > 0 && $0 <= state.config.totalTickets })
        state.config.unusedTickets = parsed
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            VStack(spacing: 8) {
                content
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct SettingsRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            content
        }
    }
}
