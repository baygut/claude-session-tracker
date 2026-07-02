import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @EnvironmentObject var store: UsageStore
    @EnvironmentObject var auth: AuthManager
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            if !auth.isSignedIn {
                signInPrompt
            } else if let usage = store.usage {
                usageRows(usage)
            } else if let error = store.errorText {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView().controlSize(.small)
            }

            Divider()
            footer
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Text("Claude Usage")
                .font(.headline)
            Spacer()
            if auth.isSignedIn {
                Button {
                    store.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh")
            }
        }
    }

    private var signInPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sign in to see your session and weekly usage limits.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Sign in to claude.ai…") {
                auth.signIn()
            }
        }
    }

    private func usageRows(_ usage: UsageResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let session = usage.session {
                usageRow(session)
            }
            if !usage.weekly.isEmpty {
                Text("Weekly limits")
                    .font(.subheadline).bold()
                ForEach(usage.weekly) { limit in
                    usageRow(limit)
                }
            }
        }
    }

    private func usageRow(_ limit: UsageLimit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(limit.displayName)
                    .font(.caption).bold()
                Spacer()
                Text("resets in \(limit.resetsInText)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ProgressView(value: Double(limit.percent) / 100.0)
                    .tint(progressColor(limit.percent))
                Text("\(limit.percent)% used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 62, alignment: .trailing)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if auth.isSignedIn {
                HStack {
                    Text("Updated \(store.lastUpdatedText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if store.isLoading {
                        ProgressView().controlSize(.small)
                    }
                }
            }
            HStack {
                Button("Settings…") { openSettings() }
                    .buttonStyle(.plain)
                    .font(.caption)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
            }
        }
    }

    private func progressColor(_ percent: Int) -> Color {
        if percent >= 90 { return .red }
        if percent >= 65 { return .orange }
        return .blue
    }
}
