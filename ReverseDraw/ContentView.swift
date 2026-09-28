import SwiftUI

struct ContentView: View {
    @Environment(EventState.self) private var state
    @State private var showRestoreAlert = false
    @State private var hasCheckedForSession = false

    var body: some View {
        Group {
            if state.phase == .setup {
                SetupView()
            } else {
                OperatorView()
            }
        }
        .alert("Restore Previous Session?", isPresented: $showRestoreAlert) {
            Button("Resume") { state.loadSession() }
            Button("Start Fresh", role: .destructive) { state.reset() }
        } message: {
            Text("A previous event session was found. Continue where you left off?")
        }
        .onAppear {
            // Guard against re-firing: onAppear can retrigger when this view
            // reappears (e.g. switching back into a tab/split pane), and the
            // session file exists for the entire duration of an event, so an
            // unguarded check would re-prompt constantly mid-event.
            guard !hasCheckedForSession else { return }
            hasCheckedForSession = true
            if PersistenceManager.shared.hasSession {
                showRestoreAlert = true
            }
        }
    }
}
