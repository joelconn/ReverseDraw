# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

`xcode-select` points at CommandLineTools rather than Xcode.app — always use the full path:

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project RotaryDraw.xcodeproj \
  -scheme RotaryDraw \
  -destination 'platform=macOS,arch=arm64' \
  build
```

No test targets exist yet. There is no `swift build` / Package.swift — this is a pure Xcode project.

## Architecture

Two-window macOS app sharing a single `@Observable` `EventState` instance injected via SwiftUI environment.

**Window 1 — Operator** (light UI, main screen): `ContentView` → `SetupView` (phase `.setup`) or `OperatorView` (all other phases). `OperatorView` is a 2-column layout: controls on the left (draw button, undo, phase-specific panels), scrollable history list on the right.

**Window 2 — Audience** (dark, full-screen on external display): Opened programmatically by `WindowManager` using `NSHostingView` in an `NSWindow`. On a second screen it goes full-screen; on a single screen it opens as a resizable window on the right half. `AudienceView` routes by phase — ticket grid during drawing, `FinalTenView` for final ten, winner screen after bonus draw. `RevealOverlay` sits on top as a ZStack layer and auto-shows/dismisses whenever `state.currentReveal != nil`.

**State flow:**
`.setup` → `.drawing` (via `startEvent()`) → `.finalTen` (auto-triggered when `drawHistory.count >= config.threshold`) → `.bonusDraw` (manual) → `.complete`

**Special prizes** are keyed by **draw order position** (1st draw, 20th draw…), not ticket number. The dict key is the draw position as a String (`config.specialPrizes["20"]` = prize on the 20th draw). This was a known source of confusion — the label in SetupView deliberately reads "Draw #", not "Ticket #".

**Persistence** is handled entirely by `PersistenceManager.shared` (singleton). It writes to `~/Library/Application Support/RotaryDraw/`: `session.json` (full state after every action), `guestlist.json` (guest CSV, persists across restarts), and timestamped `session_backup_*.json` files (auto every 5 min, last 10 kept). `Snapshot` is the Codable DTO used for both undo stack entries and disk saves — the field name `eliminated` must stay as-is for decode compatibility.

**Guest list**: CSV file mapping ticket numbers to guest names and optional sponsorship levels (`TicketNumber,Name,SponsorLevel`). Loaded into `EventState.guestList: [Int: GuestInfo]` at init and whenever the user loads a new CSV from SetupView. `GuestNameplate` (defined in `RevealOverlay.swift`) is the reusable display component used on reveal and winner screens.

**Confetti**: `ConfettiView` is `NSViewRepresentable` wrapping a SpriteKit `SKView`/`ConfettiScene`. Particles are `SKShapeNode` objects animated with `SKAction` (no `.sks` files). Used inside `RevealOverlay` for special prize draws.

## Build settings to be aware of

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types are implicitly `@MainActor`. Background work needs explicit `nonisolated` or `Task.detached`.
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `ENABLE_APP_SANDBOX = YES`, `ENABLE_USER_SELECTED_FILES = readonly` — file access outside app container requires `fileImporter` / security-scoped resource access.
- Deployment target: macOS 26.5 (Tahoe). No back-deployment guards needed.
- Bundle ID: `com.joelconn.RotaryDraw`
