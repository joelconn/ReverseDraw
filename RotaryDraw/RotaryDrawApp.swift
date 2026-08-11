import SwiftUI

@main
struct RotaryDrawApp: App {
    @State private var eventState = EventState()
    #if os(macOS)
    @State private var windowManager = WindowManager()
    #else
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        Window("RotaryDraw — Operator", id: "operator") {
            ContentView()
                .environment(eventState)
                .environment(windowManager)
                .onAppear {
                    windowManager.openAudienceWindow(eventState: eventState)
                }
        }
        .defaultSize(width: 900, height: 680)
        .commandsRemoved()
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About RotaryDraw") { NSApp.orderFrontStandardAboutPanel(nil) }
            }
            CommandGroup(after: .windowArrangement) {
                Divider()
                Button("Show Audience Window") { windowManager.openAudienceWindow(eventState: eventState) }
                    .keyboardShortcut("2", modifiers: .command)
            }
        }
        #else
        WindowGroup {
            iPadRootView()
                .environment(eventState)
                .onAppear {
                    appDelegate.eventState = eventState
                    appDelegate.connectExternalDisplayIfNeeded()
                }
        }
        #endif
    }
}

#if os(iOS)
struct iPadRootView: View {
    @Environment(EventState.self) private var state
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasExternalDisplay = UIScreen.screens.count > 1

    var body: some View {
        Group {
            if hasExternalDisplay {
                // Audience is mirrored to the external display by AppDelegate;
                // the iPad itself shows just the operator controls.
                ContentView()
            } else {
                HStack(spacing: 0) {
                    ContentView()
                        .frame(width: 420)
                    Divider().ignoresSafeArea()
                    AudienceView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.didConnectNotification)) { _ in
            hasExternalDisplay = UIScreen.screens.count > 1
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.didDisconnectNotification)) { _ in
            hasExternalDisplay = UIScreen.screens.count > 1
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { hasExternalDisplay = UIScreen.screens.count > 1 }
        }
    }
}
#endif
