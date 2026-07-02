import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var store: UsageStore

    var body: some View {
        Form {
            Section {
                if auth.isSignedIn {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Signed in to claude.ai")
                        Spacer()
                        Button("Sign out") {
                            auth.signOut()
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sign in to claude.ai to show your real session and weekly usage limits (the same numbers as Settings > Usage on the website).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Sign in…") {
                            auth.signIn()
                        }
                    }
                }
            } header: {
                Text("Account")
            }

            Section {
                Picker("Refresh every", selection: $store.refreshIntervalSeconds) {
                    Text("30s").tag(30.0)
                    Text("1 min").tag(60.0)
                    Text("5 min").tag(300.0)
                }
                .pickerStyle(.menu)
            } header: {
                Text("Display")
            }

            Section {
                Text("Reads usage data directly from claude.ai using your signed-in session. This is an unofficial, undocumented endpoint the claude.ai website itself uses — it isn't a public API, so it could change or break without notice. Nothing is sent anywhere except claude.ai.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("About")
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
