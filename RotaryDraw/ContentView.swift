import SwiftUI

struct ContentView: View {
    @Environment(EventState.self) private var state
    @State private var showRestoreAlert = false

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
            if PersistenceManager.shared.hasSession {
                showRestoreAlert = true
            }
        }
    }
}
