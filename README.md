# Claude Session Tracker

A macOS menu bar app that shows your real Claude usage limits — the same
numbers as the **Settings → Usage** panel on claude.ai — without having to
open a browser.

![Claude Session Tracker screenshot](../screenshot.png)

## What it shows

- **Current session** — your 5-hour rate-limit window: percent used and
  time until it resets.
- **Weekly limits** — one row per weekly limit on your plan (e.g. "All
  models", plus any model-specific limits like "Fable"), each with percent
  used and time until reset.

This isn't an estimate. The app calls the same (private, undocumented)
endpoint claude.ai's own web UI calls — `GET
https://claude.ai/api/organizations/{id}/usage` — authenticated with your
own claude.ai session, so the numbers always match what you'd see on the
website.

## How sign-in works

Click the menu bar icon → **Sign in to claude.ai…**. This opens a real,
embedded claude.ai login page inside the app — you type your credentials
there, the same as in a browser. The app only reads the resulting session
cookie afterward (stored in the macOS Keychain) so it can keep refreshing
your usage in the background without keeping a window open. Nothing is
sent anywhere except claude.ai, and your password never passes through
the app itself.

If a session expires, the app detects it, signs you out automatically,
and prompts you to sign in again.

## Caveat

This relies on an internal claude.ai API that isn't publicly documented.
Anthropic could change or remove it at any time, which would break the
app until it's updated.

## Build & run

Requires macOS 13+ and Xcode Command Line Tools (`xcode-select --install`).

```bash
cd ClaudeSessionTracker
./build.sh
```

This produces `ClaudeSessionTracker.app`. Move it to `/Applications` and
double-click to launch (first launch: right-click → Open, since it isn't
notarized/signed).

For quick iteration during development, you can also just run:

```bash
swift run
```

## Project layout

```
ClaudeSessionTracker/
  Package.swift
  Sources/ClaudeSessionTracker/
    App.swift                  — app entry point (MenuBarExtra scene)
    AuthManager.swift          — embedded claude.ai sign-in (WKWebView) + Keychain
    ClaudeAPIClient.swift      — calls claude.ai's usage endpoint
    KeychainHelper.swift       — stores the session cookie securely
    Models.swift               — usage/limit data structures
    UsageStore.swift           — observable state, timer-based refresh
    MenuBarLabel.swift         — status bar icon/text
    MenuBarContentView.swift   — dropdown UI (session + weekly limit bars)
    SettingsWindowController.swift — opens the settings window on demand
    SettingsView.swift         — settings window (sign in/out, refresh interval)
  Resources/Info.plist         — LSUIElement (no Dock icon), bundle metadata
  build.sh                     — builds & packages the .app
```

## Ideas for later

- Launch-at-login (via `SMAppService`)
- Notifications when a limit crosses a threshold (e.g. 90%)
- Support for orgs with multiple workspaces
