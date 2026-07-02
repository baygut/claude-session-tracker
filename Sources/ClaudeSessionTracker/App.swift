import SwiftUI

@main
struct ClaudeSessionTrackerApp: App {
    @StateObject private var auth: AuthManager
    @StateObject private var store: UsageStore
    private let settingsWindow = SettingsWindowController()

    init() {
        let auth = AuthManager()
        _auth = StateObject(wrappedValue: auth)
        _store = StateObject(wrappedValue: UsageStore(auth: auth))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(openSettings: { [settingsWindow] in
                settingsWindow.show(auth: auth, store: store)
            })
            .environmentObject(store)
            .environmentObject(auth)
            .onAppear { store.start() }
        } label: {
            MenuBarLabel()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}
