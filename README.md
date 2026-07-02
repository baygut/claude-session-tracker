# Claude Session Tracker

A macOS menu bar app that tracks your **Claude Code** usage: the current
5-hour rate-limit session window, today's totals, and the last 7 days.

It reads your local Claude Code transcripts at `~/.claude/projects/**/*.jsonl`
— no login, no network calls, nothing leaves your Mac.

## Important caveat

Anthropic doesn't publish an exact token quota per session or per day, and
there's no public API for claude.ai's own usage limits. This app can only
show you **your actual token usage**, not an official "% of limit." The
session progress bar compares your usage against a **budget you set yourself**
in Settings — tune it over a few days until it roughly matches when you
actually start hitting rate limits.

## What it shows

- **Current session** — a rolling 5-hour window (mirrors how Claude's own
  rate limits behave: the window starts at your first message and resets
  5 hours later, or sooner if you go quiet for 5+ hours).
- **Today** — total tokens, messages, and estimated cost since midnight.
- **Last 7 days** — same, rolling window.

Cost estimates use a small built-in pricing table (Opus/Sonnet/Haiku,
mid-2025 rates) and are approximate — Anthropic's actual pricing may differ
or change.

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
    App.swift              — app entry point (MenuBarExtra + settings window)
    UsageStore.swift        — observable state, timer-based refresh, settings
    LogParser.swift         — reads & parses ~/.claude/projects/**/*.jsonl
    Models.swift             — data structures + pricing table
    MenuBarLabel.swift       — status bar icon/text
    MenuBarContentView.swift — dropdown UI
    SettingsView.swift       — settings window
  Resources/Info.plist       — LSUIElement (no Dock icon), bundle metadata
  build.sh                   — builds & packages the .app
```

## Ideas for later

- Launch-at-login (via `SMAppService`)
- Per-project breakdown
- Menu bar text style options (icon-only vs. token count vs. time remaining)
