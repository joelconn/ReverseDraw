#if os(macOS)
import SwiftUI
import AppKit
import Observation

@MainActor
@Observable
final class WindowManager {
    private(set) var audienceWindow: NSWindow?

    func openAudienceWindow(eventState: EventState) {
        guard audienceWindow == nil else { return }

        let screens = NSScreen.screens
        let multiScreen = screens.count > 1
        let targetScreen = multiScreen ? screens[1] : screens[0]

        let window = NSWindow(
            contentRect: targetScreen.visibleFrame,
            styleMask: multiScreen
                ? [.borderless, .fullSizeContentView]
                : [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: targetScreen
        )

        let content = AudienceView()
            .environment(eventState)

        window.contentView = NSHostingView(rootView: content)
        window.backgroundColor = .black
        window.title = "Audience Display"

        if multiScreen {
            window.setFrame(targetScreen.frame, display: true)
            window.isMovable = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
            window.level = .mainMenu + 1
            window.makeKeyAndOrderFront(nil)
            window.toggleFullScreen(nil)
        } else {
            // Single screen: show a resizable window on the right half
            let screenFrame = targetScreen.visibleFrame
            let w = screenFrame.width * 0.52
            let h = screenFrame.height * 0.80
            let x = screenFrame.maxX - w - 10
            let y = screenFrame.minY + (screenFrame.height - h) / 2
            window.setFrame(CGRect(x: x, y: y, width: w, height: h), display: true)
            window.collectionBehavior = [.managed]
            window.level = .normal
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.makeKeyAndOrderFront(nil)
        }

        audienceWindow = window
    }

    func closeAudienceWindow() {
        audienceWindow?.close()
        audienceWindow = nil
    }
}
#endif
