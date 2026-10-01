import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    overviewSection
                    phasesSection
                    drawingSection
                    finalTenSection
                    bonusSection
                    shortcutsSection
                    tipsSection
                }
                .padding(24)
            }
            .navigationTitle("How to Use ReverseDraw")
            #if os(macOS)
            .navigationSubtitle("Operator guide")
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, idealWidth: 580, minHeight: 500, idealHeight: 680)
        #endif
    }

    // MARK: - Sections

    private var overviewSection: some View {
        HelpSection(title: "Overview", icon: "info.circle.fill", color: .blue) {
            HelpParagraph("ReverseDraw runs a reverse-lottery style fundraising event. Tickets are drawn one at a time from a pool — the last ticket(s) remaining win the prize. The event runs in five phases: Setup, Main Draw, Final Ten, Bonus Draw, and Complete.")
            HelpParagraph("The Operator screen (your device) controls the draw. The Audience screen (your projector or external display) shows winners to the crowd.")
        }
    }

    private var phasesSection: some View {
        HelpSection(title: "Event Phases", icon: "arrow.right.circle.fill", color: .purple) {
            HelpStep(number: "1", title: "Setup", color: .gray) {
                Text("Configure your event: enter a name, total ticket count, Final Ten threshold, prize amounts, and special draw prizes. Import your guest list CSV if you have one. Tap **Start Event** when ready.")
            }
            HelpStep(number: "2", title: "Main Draw", color: .blue) {
                Text("Draw tickets one at a time. Each draw reveals a ticket on the audience screen. Press **Draw Next Ticket** (or Space) to draw. If the ticket holder is not present, press **Not Present** to void their ticket — the prize carries over to the next draw.")
            }
            HelpStep(number: "3", title: "Final Ten", color: .teal) {
                Text("Automatically begins after the Main Draw threshold is reached. The remaining tickets are now contestants. Press **Draw Elimination** to eliminate one contestant at a time. Once you're ready to end — press **Split Pot** to divide the Final Ten prize equally among all remaining contestants.")
            }
            HelpStep(number: "4", title: "Bonus Draw", color: .orange) {
                Text("All tickets are reset into a fresh pool. Press **Draw Bonus Ticket** to draw the grand prize winner from all tickets. If the winner is not present, press **Not Present** to redraw. Press **Complete Event** to finish.")
            }
            HelpStep(number: "5", title: "Complete", color: .green) {
                Text("The event is finished and archived automatically. Results are saved to your device. Press **Start New Event** to begin a fresh event.")
            }
        }
    }

    private var drawingSection: some View {
        HelpSection(title: "During the Main Draw", icon: "ticket.fill", color: .blue) {
            HelpRow(icon: "ticket.fill", label: "Draw Next Ticket") {
                Text("Draws a random ticket and shows it on the Audience screen. Press again (or Space) to dismiss the reveal and enable the next draw.")
            }
            HelpRow(icon: "person.slash.fill", label: "Not Present") {
                Text("Marks the last drawn ticket as not present. The ticket is voided and its prize (if any) carries over to the next special draw position. Available immediately after a draw.")
            }
            HelpRow(icon: "arrow.uturn.backward", label: "Undo") {
                Text("Reverses the last draw. You can undo multiple draws in sequence. Useful if you drew the wrong ticket or made a mistake.")
            }
            HelpRow(icon: "exclamationmark.triangle.fill", label: "Prize Carry-Over") {
                Text("If a special prize ticket is marked Not Present, an orange banner shows the prize amount carrying over to the next special draw position.")
            }
        }
    }

    private var finalTenSection: some View {
        HelpSection(title: "During the Final Ten", icon: "person.3.fill", color: .teal) {
            HelpRow(icon: "ticket.fill", label: "Draw Elimination") {
                Text("Randomly eliminates one contestant. The pot-split amount updates live as contestants are eliminated.")
            }
            HelpRow(icon: "xmark.circle.fill", label: "Not Present (menu)") {
                Text("Tap to see a list of current contestants. Select one to eliminate them manually if they are not present.")
            }
            HelpRow(icon: "dollarsign.circle.fill", label: "Split Pot") {
                Text("Ends the Final Ten and divides the prize pot equally among all remaining contestants. Everyone on screen at this moment wins. You can split with any number of contestants remaining — 2, 3, or more.")
            }
        }
    }

    private var bonusSection: some View {
        HelpSection(title: "During the Bonus Draw", icon: "star.fill", color: .orange) {
            HelpParagraph("All tickets re-enter the draw — including previously eliminated Final Ten contestants and tickets drawn earlier in the Main Draw. Anyone who purchased a ticket is eligible.")
            HelpParagraph("Draw one ticket for the grand prize. If the winner is not present, press **Not Present** to draw again. Once you have a present winner, press **Complete Event** to end the event and save results.")
        }
    }

    private var shortcutsSection: some View {
        HelpSection(title: "Keyboard Shortcuts", icon: "keyboard.fill", color: .secondary) {
            HelpKeyboardRow(key: "Space", action: "Draw next ticket / dismiss reveal")
            HelpKeyboardRow(key: "⌘Z", action: "Undo last draw")
        }
    }

    private var tipsSection: some View {
        HelpSection(title: "Tips", icon: "lightbulb.fill", color: .yellow) {
            HelpRow(icon: "externaldrive.fill", label: "Auto-Save") {
                Text("The event is saved automatically after every action. If the app closes unexpectedly, relaunch and choose **Resume** on the Setup screen.")
            }
            HelpRow(icon: "display", label: "External Display") {
                Text("Connect your projector or external display before launching. On Mac, the Audience window opens automatically on the second screen. On iPad, it mirrors to the connected display.")
            }
            HelpRow(icon: "rectangle.righthalf.inset.fill", label: "Reopen Audience Window") {
                Text("On Mac, if the Audience window is closed, press the split-screen icon in the top-left of the Operator screen to reopen it.")
            }
            HelpRow(icon: "doc.text", label: "Guest List CSV") {
                Text("Format: TicketNumber,Name,SponsorLevel (one per line). SponsorLevel is optional. Import from Setup before starting the event.")
            }
        }
    }
}

// MARK: - Reusable Components

private struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline.bold())
                Text(title)
                    .font(.headline)
            }
            Divider()
            content
        }
    }
}

private struct HelpParagraph: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HelpStep<Content: View>: View {
    let number: String
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(color, in: Circle())
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                content
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HelpRow<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.subheadline.bold())
                content
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HelpKeyboardRow: View {
    let key: String
    let action: String

    var body: some View {
        HStack {
            Text(key)
                .font(.system(.subheadline, design: .monospaced).bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            Text(action)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HelpView()
}
