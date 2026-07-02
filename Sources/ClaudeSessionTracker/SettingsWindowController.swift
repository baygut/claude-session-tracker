import AppKit
import SwiftUI

/// Shows the Settings view in a plain AppKit window created on demand.
/// (Deliberately not a SwiftUI `WindowGroup` — those auto-open a window the
/// moment the app launches, which we don't want for a menu-bar-only app.)
@MainActor
final class SettingsWindowController {
    private var windowController: NSWindowController?

    func show(auth: AuthManager, store: UsageStore) {
        if let controller = windowController {
            controller.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView()
            .environmentObject(auth)
            .environmentObject(store)
        let hosting = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hosting)
        window.title = "Claude Session Tracker Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 380, height: 260))
        window.center()

        let controller = NSWindowController(window: window)
        windowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
