import SwiftUI

@main
struct RotaryDrawApp: App {
    @State private var eventState = EventState()
    #if os(macOS)
    @State private var windowManager = WindowManager()
    #endif

    var body: some Scene {
        #if os(macOS)
        Window("RotaryDraw — Operator", id: "operator") {
            ContentView()
                .environment(eventState)
                .onAppear {
                    windowManager.openAudienceWindow(eventState: eventState)
                }
        }
        .defaultSize(width: 900, height: 680)
        #else
        WindowGroup {
            iPadRootView()
                .environment(eventState)
        }
        #endif
    }
}

#if os(iOS)
struct iPadRootView: View {
    @Environment(EventState.self) private var state

    var body: some View {
        TabView {
            ContentView()
                .tabItem { Label("Operator", systemImage: "slider.horizontal.3") }
            AudienceView()
                .tabItem { Label("Audience", systemImage: "tv") }
        }
    }
}
#endif
