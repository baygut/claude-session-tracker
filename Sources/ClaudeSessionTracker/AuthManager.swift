import AppKit
import WebKit
import Combine

/// Handles signing in to claude.ai inside an embedded, real web view — you
/// type your own credentials into the actual claude.ai login page, exactly
/// like using a browser. This class only reads the resulting session
/// cookies afterwards (stored in the Keychain) so background requests can
/// be made without keeping a window open.
@MainActor
final class AuthManager: NSObject, ObservableObject, NSWindowDelegate {
    @Published var isSignedIn: Bool
    @Published var lastAuthError: String?

    private var windowController: NSWindowController?
    private var webView: WKWebView?
    private var pollTimer: Timer?
    private var continueButton: NSButton?
    private var statusLabel: NSTextField?

    override init() {
        isSignedIn = KeychainHelper.load() != nil
        super.init()
    }

    var cookieHeader: String? {
        KeychainHelper.load()
    }

    func signIn() {
        lastAuthError = nil
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 480, height: 640))
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView = webView

        let statusLabel = NSTextField(labelWithString: "Log in above. This closes automatically once you're signed in.")
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.lineBreakMode = .byWordWrapping
        self.statusLabel = statusLabel

        let continueButton = NSButton(title: "I've signed in — Continue", target: self, action: #selector(manualContinueTapped))
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.bezelStyle = .rounded
        self.continueButton = continueButton

        let bottomBar = NSStackView(views: [statusLabel, continueButton])
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.orientation = .horizontal
        bottomBar.spacing = 12
        bottomBar.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 680))
        container.addSubview(webView)
        container.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])

        let window = NSWindow(
            contentRect: container.frame,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Sign in to claude.ai"
        window.contentView = container
        window.center()
        window.delegate = self

        let controller = NSWindowController(window: window)
        windowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)

        webView.load(URLRequest(url: URL(string: "https://claude.ai/login")!))

        // Poll in the background so the window closes itself once you're
        // signed in — you don't have to click Continue unless auto-detect
        // is slow to notice.
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.attemptCapture(interactive: false) }
        }
    }

    @objc private func manualContinueTapped() {
        attemptCapture(interactive: true)
    }

    private func attemptCapture(interactive: Bool) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self else { return }
            let claudeCookies = cookies.filter { $0.domain.contains("claude.ai") }
            guard !claudeCookies.isEmpty else {
                Task { @MainActor in
                    if interactive { self.reportNotSignedInYet() }
                }
                return
            }

            let header = claudeCookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            Task { @MainActor in
                await self.validate(cookieHeader: header, interactive: interactive)
            }
        }
    }

    /// Rather than guessing which specific cookie name claude.ai uses for
    /// its session (that's an implementation detail that could change), we
    /// just try the cookies we have against the real API and see if it
    /// accepts them.
    private func validate(cookieHeader: String, interactive: Bool) async {
        var request = URLRequest(url: URL(string: "https://claude.ai/api/organizations")!)
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://claude.ai", forHTTPHeaderField: "Origin")
        request.setValue("https://claude.ai/", forHTTPHeaderField: "Referer")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                if interactive { reportNotSignedInYet() }
                return
            }
            guard http.statusCode == 200 else {
                if interactive { reportNotSignedInYet(statusCode: http.statusCode) }
                return
            }
            KeychainHelper.save(cookieHeader)
            isSignedIn = true
            lastAuthError = nil
            closeSignInWindow()
        } catch {
            if interactive { reportNotSignedInYet() }
        }
    }

    private func reportNotSignedInYet(statusCode: Int? = nil) {
        let suffix = statusCode.map { " (server said HTTP \($0))" } ?? ""
        statusLabel?.stringValue = "Not signed in yet\(suffix) — finish logging in above, then click Continue."
        statusLabel?.textColor = .systemOrange
    }

    private func closeSignInWindow() {
        pollTimer?.invalidate()
        pollTimer = nil
        windowController?.close()
        windowController = nil
        webView = nil
        continueButton = nil
        statusLabel = nil
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            self.pollTimer?.invalidate()
            self.pollTimer = nil
        }
    }

    func signOut() {
        KeychainHelper.clear()
        isSignedIn = false
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            let claudeRecords = records.filter { $0.displayName.contains("claude.ai") }
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: claudeRecords) {}
        }
    }
}
