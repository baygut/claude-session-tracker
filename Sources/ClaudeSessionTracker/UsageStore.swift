import Foundation
import Combine

@MainActor
final class UsageStore: ObservableObject {
    @Published var usage: UsageResponse?
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var lastUpdated: Date?

    @Published var refreshIntervalSeconds: Double {
        didSet {
            UserDefaults.standard.set(refreshIntervalSeconds, forKey: Keys.refreshInterval)
            restartTimer()
        }
    }

    private enum Keys {
        static let refreshInterval = "refreshIntervalSeconds"
    }

    let auth: AuthManager
    private var organizationId: String?
    private var timer: Timer?
    private var authCancellable: AnyCancellable?

    init(auth: AuthManager) {
        self.auth = auth
        self.refreshIntervalSeconds = UserDefaults.standard.object(forKey: Keys.refreshInterval) as? Double ?? 60

        authCancellable = auth.$isSignedIn.sink { [weak self] signedIn in
            guard let self else { return }
            if signedIn {
                self.refresh()
            } else {
                self.usage = nil
                self.organizationId = nil
                self.errorText = nil
            }
        }
    }

    func start() {
        if auth.isSignedIn { refresh() }
        restartTimer()
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        guard let cookie = auth.cookieHeader else {
            errorText = "Sign in to see your Claude usage."
            return
        }
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let orgId = try await resolveOrganizationId(cookie: cookie)
                let result = try await ClaudeAPIClient.fetchUsage(organizationId: orgId, cookie: cookie)
                self.usage = result
                self.lastUpdated = Date()
                self.errorText = nil
            } catch let error as ClaudeAPIClient.APIError {
                self.errorText = error.description
                if case .httpError(let code) = error, code == 401 || code == 403 {
                    // The stored cookie no longer works — clear it so the UI
                    // goes back to a clean "sign in" state instead of
                    // repeating a stale error every refresh.
                    self.organizationId = nil
                    self.auth.signOut()
                    self.errorText = "Your claude.ai session expired. Sign in again."
                }
            } catch {
                self.errorText = "Couldn't reach claude.ai (\(error.localizedDescription))."
            }
            self.isLoading = false
        }
    }

    private func resolveOrganizationId(cookie: String) async throws -> String {
        if let organizationId { return organizationId }
        let id = try await ClaudeAPIClient.fetchOrganizationId(cookie: cookie)
        organizationId = id
        return id
    }

    // MARK: - Derived, UI-friendly values

    var menuBarText: String {
        guard let percent = usage?.session?.percent else { return auth.isSignedIn ? "…" : "sign in" }
        return "\(percent)%"
    }

    var lastUpdatedText: String {
        guard let lastUpdated else { return "never" }
        let seconds = Int(Date().timeIntervalSince(lastUpdated))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60) min ago" }
        return "\(seconds / 3600) hr ago"
    }
}
