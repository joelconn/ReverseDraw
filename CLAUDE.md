# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

`xcode-select` points at CommandLineTools rather than Xcode.app — always use the full path:

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project ReverseDraw.xcodeproj \
  -scheme ReverseDraw \
  -destination 'platform=macOS,arch=arm64' \
  build
```

Unit tests: `RotaryDrawTests` target, Swift Testing framework (`@Test`/`#expect`, not XCTest). Run via `xcodebuild test -project RotaryDraw.xcodeproj -scheme RotaryDraw -destination 'platform=macOS,arch=arm64'`. Covers `EventState` game logic and `Codable` decode-compatibility for `EventConfig`/`Snapshot`. `EventState` takes an injectable `PersistenceManager` (`EventState(persistence:)`) specifically so tests can point at a temp directory instead of the real `~/Library/Application Support/RotaryDraw/` — always use that in new tests, never `.shared`. There is no `swift build` / Package.swift — this is a pure Xcode project.

## Architecture

Multiplatform (macOS + iPadOS) app sharing a single `@Observable` `EventState` instance injected via SwiftUI environment.

**Operator screen** (light UI): `ContentView` → `SetupView` (phase `.setup`) or `OperatorView` (all other phases). `OperatorView` is a 2-column layout: controls on the left (draw button, undo, phase-specific panels), scrollable history list on the right.

**Audience screen** (dark, full-screen on external display): `AudienceView` routes by phase — ticket grid during drawing, `FinalTenView` for final ten (shows split-winner amounts once `potSplitDone`), winner screen after bonus draw. `RevealOverlay` sits on top as a ZStack layer and auto-shows/dismisses whenever `state.currentReveal != nil`.

**macOS**: two `NSWindow`s. `WindowManager` opens the Audience window programmatically (`NSHostingView`) — full-screen if a second `NSScreen` is present, otherwise a resizable window on the right half.

**iPadOS**: single `WindowGroup`. `iPadRootView` shows Operator | Audience side-by-side in an `HStack` (split screen) when no external display is detected. When a TV/projector is connected (AirPlay or a video adapter), `ExternalDisplayManager.swift`'s `AppDelegate` (wired via `@UIApplicationDelegateAdaptor`) detects the new `UIScreen` via `UIScreen.didConnectNotification` and mirrors `AudienceView` onto it in a separate `UIWindow`, while the iPad itself falls back to showing just `ContentView` (operator-only). This mirrors the macOS two-window behavior without a true multi-scene setup.

**State flow:**
`.setup` → `.drawing` (via `startEvent()`) → `.finalTen` (auto-triggered when `drawHistory.count >= config.threshold`) → `.bonusDraw` (manual, gated on `potSplitDone`) → `.complete`

**Final Ten / Split Pot**: contestants are eliminated one at a time via `drawElimination()` (a random draw, reusing `RevealOverlay`, styled "ELIMINATED" in red) until `splitPot()` is called, which freezes whoever remains as winners and divides `config.finalTenPot` evenly among them (`currentPotSplit`). `drawElimination()` refuses to run once only 1 contestant remains — `splitPot()` is the only way to resolve Final Ten. `startBonusDraw()` is gated on `potSplitDone`.

**Bonus/grand prize**: `config.bonusDrawAmount` (set in Setup, separate from `finalTenPot`) is the cash amount shown on the final winner screen — don't confuse the two.

**Event archive**: after `drawBonusTicket()` completes the event, `EventState` writes a permanent `EventArchive` (draw order, special prize winners, Final Ten split winners, grand prize winner) via `PersistenceManager.saveEventArchive` to `~/Library/Application Support/RotaryDraw/Events/<eventName>_<timestamp>.json`. This is separate from `session.json` and never overwritten. `EventState.eventName` is required (non-empty) before `SetupView` allows "Start Event".

**Special prizes** are keyed by **draw order position** (1st draw, 20th draw…), not ticket number. The dict key is the draw position as a String (`config.specialPrizes["20"]` = prize on the 20th draw). This was a known source of confusion — the label in SetupView deliberately reads "Draw #", not "Ticket #".

**Persistence** is handled entirely by `PersistenceManager.shared` (singleton). It writes to `~/Library/Application Support/RotaryDraw/`: `session.json` (full state after every action), `guestlist.json` (guest CSV, persists across restarts), and timestamped `session_backup_*.json` files (auto every 5 min, last 10 kept). `Snapshot` is the Codable DTO used for both undo stack entries and disk saves — the field name `eliminated` must stay as-is for decode compatibility.

**Guest list**: CSV file mapping ticket numbers to guest names and optional sponsorship levels (`TicketNumber,Name,SponsorLevel`). Loaded into `EventState.guestList: [Int: GuestInfo]` at init and whenever the user loads a new CSV from SetupView. `GuestNameplate` (defined in `RevealOverlay.swift`) is the reusable display component used on reveal and winner screens.

**Confetti**: `ConfettiView` wraps a SpriteKit `SKView`/`ConfettiScene` — `NSViewRepresentable` on macOS, `UIViewRepresentable` on iOS. Particles are `SKShapeNode` objects animated with `SKAction` (no `.sks` files). One-shot dramatic burst inside `RevealOverlay` for special prize / grand winner / Final Ten split reveals; `loop: true` mode gives a continuous ambient burst every ~2.5s, used on the persistent `AudienceWinnerView` and the post-split `FinalTenView` so the screen doesn't go dark after the reveal overlay fades.

**Release**: `scripts/release.sh` archives (macOS only — iOS needs a separate `xcodebuild archive -destination 'generic/platform=iOS'` run) and uploads to App Store Connect via an API key (`APP_STORE_CONNECT_KEY_ID`/`_ISSUER_ID`/`_KEY_PATH` env vars). It auto-bumps the build number every run; pass a version string as `$1` to also bump `MARKETING_VERSION`. First-time signing bootstrap (new distribution certs/profiles) requires going through Xcode's Organizer → Distribute App once per platform — the CLI's API key doesn't have cloud-signing permission to create them itself.

## Build settings to be aware of

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types are implicitly `@MainActor`. Background work needs explicit `nonisolated` or `Task.detached`.
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `ENABLE_APP_SANDBOX = YES`, `ENABLE_USER_SELECTED_FILES = readonly` — file access outside app container requires `fileImporter` / security-scoped resource access.
- Deployment target: macOS 26.5 (Tahoe). No back-deployment guards needed.
- Bundle ID: `com.joelconn.ReverseDraw`
