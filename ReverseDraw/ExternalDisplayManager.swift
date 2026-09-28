#if os(iOS)
import SwiftUI
import UIKit

/// Mirrors AudienceView onto a connected external display (TV/projector via
/// AirPlay or a video adapter), the iPadOS equivalent of WindowManager's
/// second NSWindow on macOS.
final class AppDelegate: NSObject, UIApplicationDelegate {
    var eventState: EventState?
    private var externalWindow: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDidConnect), name: UIScreen.didConnectNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDidDisconnect), name: UIScreen.didDisconnectNotification, object: nil
        )
        return true
    }

    /// Call once eventState is available, and again any time the app becomes active,
    /// in case a display was already connected before eventState was wired up.
    func connectExternalDisplayIfNeeded() {
        guard externalWindow == nil, let screen = UIScreen.screens.first(where: { $0 != UIScreen.main }) else { return }
        setupExternalWindow(on: screen)
    }

    @objc private func screenDidConnect(_ note: Notification) {
        guard let screen = note.object as? UIScreen else { return }
        setupExternalWindow(on: screen)
    }

    @objc private func screenDidDisconnect(_ note: Notification) {
        externalWindow = nil
    }

    private func setupExternalWindow(on screen: UIScreen) {
        guard let eventState else { return }
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.rootViewController = UIHostingController(rootView: AudienceView().environment(eventState))
        window.isHidden = false
        externalWindow = window
    }

    var hasExternalDisplay: Bool {
        UIScreen.screens.count > 1
    }
}
#endif
