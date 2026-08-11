import SwiftUI
import UniformTypeIdentifiers

struct SetupView: View {
    @Environment(EventState.self) private var state

    @State private var newDrawNumber: String = ""
    @State private var newPrizeAmount: String = ""
    @State private var showAddRow = false
    @State private var guestLoadResult: String? = nil
    @State private var showFilePicker = false

    var sortedSpecialPrizes: [(key: String, value: Double)] {
        state.config.specialPrizes
            .sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
    }

    var body: some View {
        @Bindable var state = state

        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Rotary Reverse Drawing")
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
                        }
                        Divider()
                        SettingsRow(label: "Total Revenue") {
                            Text(state.config.totalRevenue, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                                .frame(width: 120, alignment: .trailing)
                        }
                        SettingsRow(label: "Prize Pool (50%)") {
                            Text(state.config.totalPrizePool, format: .currency(code: "USD"))
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                                .frame(width: 120, alignment: .trailing)
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

                        if showAddRow {
                            HStack(spacing: 8) {
                                TextField("Draw #", text: $newDrawNumber)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 90)
                                TextField("Prize $", text: $newPrizeAmount)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 110)
                                Button("Add") {
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

                        Button {
                            showAddRow = true
                        } label: {
                            Label("Add Special Prize Draw", systemImage: "plus.circle")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }

                    SettingsSection(title: "Guest List (optional)") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CSV format: TicketNumber, Name, SponsorLevel")
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
                }
                .frame(maxWidth: 440)

                Button("Start Event") { state.startEvent() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .disabled(state.eventName.trimmingCharacters(in: .whitespaces).isEmpty)

                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
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
