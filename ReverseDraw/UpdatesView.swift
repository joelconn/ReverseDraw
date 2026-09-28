import SwiftUI

struct UpdatesView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("v1.4")
                                .font(.headline.bold())
                                .foregroundStyle(.blue)
                            Spacer()
                            Text("Current")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            FeatureItem(title: "Prize Money Calculator", description: "Auto-calculate prize pool from ticket count & price (50% by law)")
                            FeatureItem(title: "Event Settings Automation", description: "Total tickets, Final Ten threshold, and final pot auto-calculate")
                            FeatureItem(title: "Setup Templates", description: "Save & load event configurations. Pre-built Summer Sizzle template included")
                            FeatureItem(title: "CSV Guest List", description: "Import guest names & sponsor levels (Paddle #, First name, Last name)")
                            FeatureItem(title: "Special Prize Configuration", description: "Set prize amounts for specific draw positions (1st, 20th, etc.)")
                            FeatureItem(title: "Final Ten Phase", description: "Elimination draws, split pot among remaining contestants")
                            FeatureItem(title: "Bonus Draw", description: "Grand prize draw after Final Ten with separate bonus amount")
                            FeatureItem(title: "Confetti Effects", description: "Celebration animations for special prizes, winners, and Final Ten split")
                            FeatureItem(title: "Session Recovery", description: "Auto-save after every action. Resume from crash via 'Resume Event' button")
                            FeatureItem(title: "Window Recovery (macOS)", description: "Reopen closed Audience or Operator windows without relaunching")
                            FeatureItem(title: "Manual Recovery", description: "Re-enter drawn ticket numbers to rebuild event state from scratch")
                            FeatureItem(title: "Mid-Game Settings", description: "Adjust reveal durations, bonus amount, and special prize amounts during play")
                            FeatureItem(title: "Always-Available Draw", description: "Draw button stays enabled—skip timer delays for faster play or testing")
                            FeatureItem(title: "Not Present Button", description: "Stays available after reveal closes to mark tickets as absent")
                            FeatureItem(title: "Draw # Display", description: "Shows draw position on reveal screen")
                            FeatureItem(title: "Undo/Redo", description: "Undo up to 20 actions. Available in all phases including Final Ten")
                            FeatureItem(title: "Multiplatform", description: "Runs on macOS and iPadOS with native multi-window support")
                        }
                    }
                    .padding(.vertical, 8)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Technical Highlights")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            FeatureItem(title: "SwiftUI @Observable", description: "Modern state management across operator & audience views")
                            FeatureItem(title: "SpriteKit Confetti", description: "Custom particle animations with SKAction")
                            FeatureItem(title: "Atomic File Writes", description: "Session saves never corrupt (atomic writes to disk)")
                            FeatureItem(title: "Auto-Backups", description: "Rolling 10-backup history every 5 minutes")
                            FeatureItem(title: "Computed Properties", description: "Prize pool, thresholds, and pots auto-update from inputs")
                            FeatureItem(title: "Event Archives", description: "Timestamped permanent records of completed events")
                        }
                    }
                    .padding(.vertical, 8)

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Updates")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FeatureItem: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    UpdatesView()
}
